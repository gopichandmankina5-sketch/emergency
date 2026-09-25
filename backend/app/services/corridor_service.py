import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone
from app.database.connection import db
from app.algorithms.corridor_algorithm import corridor_engine
from app.notifications.fcm_handler import fcm_handler
from app.services.location_service import location_service
from app.models.schemas import ActionType, AlertType

logger = logging.getLogger("corridor_service")

class CorridorService:
    def __init__(self):
        self.latest_analytics_rows: List[Dict[str, Any]] = []
        # Alert State Tracking for Notification Deduplication: vehicleId -> last action string
        self.last_dispatched_actions: Dict[str, str] = {}

    def update_vehicle_location(self, data: Dict[str, Any]):
        data["lastUpdated"] = data.get("lastUpdated") or datetime.now(timezone.utc).isoformat()
        db.upsert_vehicle(data)
        # Auto-recalculate if emergency vehicle is active
        active_ev = db.get_active_emergency_vehicle()
        if active_ev:
            self.recalculate_and_dispatch(active_ev["vehicleId"])

    def register_fcm_token(self, vehicle_id: str, fcm_token: str) -> Dict[str, Any]:
        res = db.update_fcm_token(vehicle_id, fcm_token)
        return {"status": "REGISTERED", "vehicleId": vehicle_id, "fcmToken": fcm_token}

    def start_emergency(self, data: Dict[str, Any]):
        ev_id = data["vehicleId"]
        db.deactivate_alerts_for_emergency(ev_id)
        self.last_dispatched_actions.clear()

        ev_data = {
            "vehicleId": ev_id,
            "type": data.get("type", "AMBULANCE"),
            "latitude": data["latitude"],
            "longitude": data["longitude"],
            "speed": data.get("speed", 45.0),
            "heading": data.get("heading", 90.0),
            "emergencyActive": True,
            "destination": data["destination"],
            "lastUpdated": datetime.now(timezone.utc).isoformat()
        }
        db.upsert_emergency_vehicle(ev_data)
        return self.recalculate_and_dispatch(ev_id)

    def update_emergency_location(self, data: Dict[str, Any]):
        active_ev = db.get_active_emergency_vehicle()
        if active_ev and active_ev["vehicleId"] == data["vehicleId"]:
            active_ev["latitude"] = data["latitude"]
            active_ev["longitude"] = data["longitude"]
            active_ev["speed"] = data.get("speed", active_ev.get("speed", 45.0))
            active_ev["heading"] = data.get("heading", active_ev.get("heading", 90.0))
            active_ev["lastUpdated"] = datetime.now(timezone.utc).isoformat()
            db.upsert_emergency_vehicle(active_ev)
            return self.recalculate_and_dispatch(data["vehicleId"])
        return None

    def stop_emergency(self, vehicle_id: str):
        active_ev = db.get_active_emergency_vehicle()
        if active_ev and active_ev["vehicleId"] == vehicle_id:
            active_ev["emergencyActive"] = False
            db.upsert_emergency_vehicle(active_ev)
            self.last_dispatched_actions.clear()
            db.deactivate_alerts_for_emergency(vehicle_id)
            db.deactivate_infrastructure_alerts_for_emergency(vehicle_id)
            return {"status": "STOPPED", "vehicleId": vehicle_id}
        
        # Ensure lingering active alerts for vehicle_id are deactivated
        db.deactivate_alerts_for_emergency(vehicle_id)
        db.deactivate_infrastructure_alerts_for_emergency(vehicle_id)
        return {"status": "STOPPED", "vehicleId": vehicle_id}

    def recalculate_and_dispatch(self, ev_id: str) -> Dict[str, Any]:
        ev = db.get_active_emergency_vehicle()
        if not ev or not ev.get("emergencyActive", False):
            db.deactivate_infrastructure_alerts_for_emergency(ev_id)
            return {"active": False, "message": "No active emergency vehicle"}

        normal_vehicles = db.get_all_normal_vehicles()
        unknown_road_users = db.get_all_unknown_road_users()
        combined_vehicles = list(normal_vehicles) + list(unknown_road_users)

        dest = ev.get("destination", {"latitude": ev["latitude"] + 0.02, "longitude": ev["longitude"] + 0.02})

        result = corridor_engine.evaluate_minimum_intervention_corridor(
            ev_id=ev["vehicleId"],
            ev_lat=ev["latitude"],
            ev_lon=ev["longitude"],
            ev_speed_kmh=ev.get("speed", 45.0),
            ev_heading=ev.get("heading", 90.0),
            dest_lat=dest["latitude"],
            dest_lon=dest["longitude"],
            nearby_vehicles=combined_vehicles
        )

        active_obstructing_unknown_ids = set()

        # Process alerts & apply notification deduplication / infrastructure simulation
        for alert in result["alerts"]:
            alert_dict = alert.dict() if hasattr(alert, 'dict') else alert
            v_id = alert_dict["vehicleId"]
            current_action_str = str(alert_dict.get("action"))
            alert_dict["active"] = True
            alert_dict["emergencyActive"] = True
            alert_dict["emergencyVehicleId"] = ev["vehicleId"]
            alert_dict.setdefault("alertId", f"alert-{v_id}-{int(datetime.now(timezone.utc).timestamp())}")

            # Check if this vehicle is an unknown road user
            unknown_user = db.get_unknown_road_user(v_id)
            if unknown_user:
                # UNKNOWN vehicle: MUST NEVER RECEIVE FCM!
                if current_action_str not in ("NO_ALERT", "ActionType.NO_ALERT"):
                    active_obstructing_unknown_ids.add(v_id)
                    action_clean = current_action_str.replace("ActionType.", "")
                    raw_text = alert_dict.get("actionText", "")
                    if " | " in raw_text:
                        action_display = raw_text.split(" | ")[-1]
                    else:
                        action_display = action_clean
                    
                    obs_score = alert_dict.get("obstructionScore", 50.0)
                    dist_m = alert_dict.get("distance", 0.0)
                    risk = "HIGH" if obs_score >= 60.0 or dist_m <= 50.0 else ("MEDIUM" if obs_score >= 35.0 else "LOW")

                    infra_alert = {
                        "alertId": f"infra-{v_id}-{ev['vehicleId']}",
                        "vehicleId": v_id,
                        "emergencyVehicleId": ev["vehicleId"],
                        "action": action_display,
                        "distanceMeters": dist_m,
                        "riskLevel": risk,
                        "registrationStatus": "UNKNOWN",
                        "deliveryChannel": "SOFTWARE_INFRASTRUCTURE_SIMULATION",
                        "deliveryStatus": "SIMULATED",
                        "active": True,
                        "createdAt": datetime.now(timezone.utc).isoformat()
                    }
                    db.save_infrastructure_alert(infra_alert)
                else:
                    db.deactivate_infrastructure_alerts_for_vehicle(v_id)
            else:
                # Registered driver vehicle
                db.save_alert(alert_dict)

                # Check if action meaningfully changed
                previous_action = self.last_dispatched_actions.get(v_id)
                if previous_action != current_action_str:
                    self.last_dispatched_actions[v_id] = current_action_str
                    
                    v_info = db.get_vehicle(v_id)
                    fcm_token = v_info.get("fcmToken") if v_info else None
                    if fcm_token:
                        fcm_handler.send_push_notification(
                            fcm_token=fcm_token,
                            title="🚨 Emergency Corridor Instruction",
                            body=alert_dict["actionText"],
                            data_payload=alert_dict
                        )
                else:
                    logger.debug(f"Action for {v_id} unchanged ({current_action_str}); push notification suppressed.")

        # Deactivate infrastructure alerts for unknown vehicles no longer obstructing
        all_active_infra = db.get_active_infrastructure_alerts(ev["vehicleId"])
        for infra in all_active_infra:
            if infra["vehicleId"] not in active_obstructing_unknown_ids:
                db.deactivate_infrastructure_alerts_for_vehicle(infra["vehicleId"])

        self.latest_analytics_rows = result.get("analyticsRows", [])
        return result

    def get_nearby_vehicles(
        self,
        max_radius_m: float = 800.0,
        lat: Optional[float] = None,
        lon: Optional[float] = None,
        max_stale_seconds: Optional[float] = None
    ) -> List[Dict[str, Any]]:
        ev = db.get_active_emergency_vehicle()
        vehicles = db.get_all_normal_vehicles(max_stale_seconds=max_stale_seconds)
        
        center_lat = lat if lat is not None else (ev["latitude"] if ev else None)
        center_lon = lon if lon is not None else (ev["longitude"] if ev else None)
        
        if center_lat is not None and center_lon is not None:
            return location_service.filter_nearby(center_lat, center_lon, vehicles, max_radius_m)
        return vehicles

    def get_corridor(self, ev_id: str) -> Dict[str, Any]:
        return self.recalculate_and_dispatch(ev_id)

    def get_alerts_for_vehicle(self, vehicle_id: str) -> List[Dict[str, Any]]:
        ev = db.get_active_emergency_vehicle()
        if not ev or not ev.get("emergencyActive", False):
            return []
        return db.get_active_alerts_by_vehicle(vehicle_id, active_emergency_id=ev["vehicleId"])

    def get_active_alert_response(self, vehicle_id: str) -> Dict[str, Any]:
        ev = db.get_active_emergency_vehicle()
        all_alerts = db.get_alerts_by_vehicle(vehicle_id)

        if not ev or not ev.get("emergencyActive", False):
            return {
                "vehicleId": vehicle_id,
                "hasAlert": False,
                "alerts": [],
                "allAlerts": all_alerts
            }

        active_alerts = db.get_active_alerts_by_vehicle(vehicle_id, active_emergency_id=ev["vehicleId"])
        if not active_alerts:
            return {
                "vehicleId": vehicle_id,
                "hasAlert": False,
                "alerts": [],
                "allAlerts": all_alerts
            }

        latest = active_alerts[-1]
        if latest.get("action") in ("NO_ALERT", "ACKNOWLEDGED"):
            return {
                "vehicleId": vehicle_id,
                "hasAlert": False,
                "alerts": [],
                "allAlerts": all_alerts
            }

        return {
            "vehicleId": vehicle_id,
            "hasAlert": True,
            "latestAlert": latest,
            "allAlerts": all_alerts
        }

    def get_analytics(self) -> Dict[str, Any]:
        return self.get_analytics_summary()

    def get_analytics_summary(self) -> Dict[str, Any]:
        ev = db.get_active_emergency_vehicle()
        vehicles = db.get_all_normal_vehicles()
        return {
            "totalVehiclesRegistered": len(vehicles),
            "activeEmergency": ev.get("vehicleId") if ev and ev.get("emergencyActive") else None,
            "latestAnalyticsRows": self.latest_analytics_rows
        }

corridor_service = CorridorService()
