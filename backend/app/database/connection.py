import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone
from app.config import settings

logger = logging.getLogger("corridor_db")

class InMemoryStore:
    """DEVELOPMENT ONLY - Non-persistent in-memory fallback store."""
    def __init__(self):
        self.vehicles: Dict[str, Dict[str, Any]] = {}
        self.emergency_vehicles: Dict[str, Dict[str, Any]] = {}
        self.alerts: List[Dict[str, Any]] = []
        self.routes: List[Dict[str, Any]] = []
        self.traffic_data: List[Dict[str, Any]] = []
        self.unknown_road_users: Dict[str, Dict[str, Any]] = {}
        self.infrastructure_alerts: List[Dict[str, Any]] = []

    def clear_all(self):
        self.vehicles.clear()
        self.emergency_vehicles.clear()
        self.alerts.clear()
        self.routes.clear()
        self.traffic_data.clear()
        self.unknown_road_users.clear()
        self.infrastructure_alerts.clear()

    def upsert_vehicle(self, data: Dict[str, Any]):
        data["lastUpdated"] = data.get("lastUpdated") or datetime.now(timezone.utc).isoformat()
        if data["vehicleId"] in self.vehicles:
            # Preserve existing fcmToken if not provided
            data["fcmToken"] = data.get("fcmToken") or self.vehicles[data["vehicleId"]].get("fcmToken")
        self.vehicles[data["vehicleId"]] = data
        return data

    def update_fcm_token(self, vehicle_id: str, fcm_token: str):
        if vehicle_id in self.vehicles:
            self.vehicles[vehicle_id]["fcmToken"] = fcm_token
        else:
            self.vehicles[vehicle_id] = {
                "vehicleId": vehicle_id,
                "fcmToken": fcm_token,
                "latitude": 13.0827,
                "longitude": 80.2707,
                "speed": 0.0,
                "heading": 0.0,
                "locationEnabled": True,
                "lastUpdated": datetime.now(timezone.utc).isoformat()
            }
        return self.vehicles[vehicle_id]

    def upsert_emergency(self, data: Dict[str, Any]):
        data["lastUpdated"] = datetime.now(timezone.utc).isoformat()
        self.emergency_vehicles[data["vehicleId"]] = data
        return data

    def get_vehicle(self, vehicle_id: str) -> Optional[Dict[str, Any]]:
        return self.vehicles.get(vehicle_id)

    def get_emergency(self, vehicle_id: str) -> Optional[Dict[str, Any]]:
        return self.emergency_vehicles.get(vehicle_id)

    def get_active_emergency(self) -> Optional[Dict[str, Any]]:
        for ev in self.emergency_vehicles.values():
            if ev.get("emergencyActive", False):
                return ev
        return None

    def add_alert(self, alert_data: Dict[str, Any]):
        if "active" not in alert_data:
            alert_data["active"] = True
        self.alerts.append(alert_data)
        return alert_data

    def deactivate_alerts_for_emergency(self, emergency_vehicle_id: str):
        for a in self.alerts:
            if a.get("emergencyVehicleId") == emergency_vehicle_id or a.get("active", True) is True:
                a["active"] = False

    def deactivate_alerts_for_vehicle(self, vehicle_id: str):
        for a in self.alerts:
            if a.get("vehicleId") == vehicle_id:
                a["active"] = False

    def get_alerts_for_vehicle(self, vehicle_id: str) -> List[Dict[str, Any]]:
        return [a for a in self.alerts if a.get("vehicleId") == vehicle_id]

    def get_active_alerts_for_vehicle(self, vehicle_id: str, active_emergency_id: Optional[str] = None) -> List[Dict[str, Any]]:
        active_list = []
        for a in self.alerts:
            if a.get("vehicleId") != vehicle_id:
                continue
            if not a.get("active", True):
                continue
            if active_emergency_id and a.get("emergencyVehicleId") and a.get("emergencyVehicleId") != active_emergency_id:
                continue
            if a.get("action") in ("NO_ALERT", "ACKNOWLEDGED"):
                continue
            active_list.append(a)
        return active_list

    def get_all_vehicles(self) -> List[Dict[str, Any]]:
        return list(self.vehicles.values())

    def get_fresh_vehicles(self, max_stale_seconds: float = 60.0) -> List[Dict[str, Any]]:
        now = datetime.now(timezone.utc)
        fresh = []
        for v in self.vehicles.values():
            ts_str = v.get("lastUpdated")
            if ts_str:
                try:
                    ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                    if ts.tzinfo is None:
                        ts = ts.replace(tzinfo=timezone.utc)
                    age = (now - ts).total_seconds()
                    if age <= max_stale_seconds:
                        fresh.append(v)
                    continue
                except Exception:
                    pass
            fresh.append(v)
        return fresh

    # Unknown Road Users Methods
    def upsert_unknown_road_user(self, data: Dict[str, Any]) -> Dict[str, Any]:
        now_str = datetime.now(timezone.utc).isoformat()
        v_id = data["vehicleId"]
        if v_id in self.unknown_road_users:
            existing = self.unknown_road_users[v_id]
            data["createdAt"] = existing.get("createdAt", now_str)
        else:
            data["createdAt"] = data.get("createdAt", now_str)
        data["registrationStatus"] = "UNKNOWN"
        data["lastSeen"] = now_str
        self.unknown_road_users[v_id] = data
        return data

    def get_unknown_road_user(self, vehicle_id: str) -> Optional[Dict[str, Any]]:
        return self.unknown_road_users.get(vehicle_id)

    def get_all_unknown_road_users(self) -> List[Dict[str, Any]]:
        return list(self.unknown_road_users.values())

    def delete_unknown_road_user(self, vehicle_id: str) -> bool:
        if vehicle_id in self.unknown_road_users:
            del self.unknown_road_users[vehicle_id]
            self.deactivate_infrastructure_alerts_for_vehicle(vehicle_id)
            return True
        return False

    # Infrastructure Alerts Methods
    def save_infrastructure_alert(self, alert_data: Dict[str, Any]) -> Dict[str, Any]:
        alert_data["active"] = alert_data.get("active", True)
        v_id = alert_data.get("vehicleId")
        ev_id = alert_data.get("emergencyVehicleId")
        for a in self.infrastructure_alerts:
            if a.get("vehicleId") == v_id and a.get("emergencyVehicleId") == ev_id:
                a["active"] = False
        self.infrastructure_alerts.append(alert_data)
        return alert_data

    def deactivate_infrastructure_alerts_for_emergency(self, emergency_vehicle_id: str):
        for a in self.infrastructure_alerts:
            if a.get("emergencyVehicleId") == emergency_vehicle_id:
                a["active"] = False

    def deactivate_infrastructure_alerts_for_vehicle(self, vehicle_id: str):
        for a in self.infrastructure_alerts:
            if a.get("vehicleId") == vehicle_id:
                a["active"] = False

    def get_active_infrastructure_alerts(self, emergency_vehicle_id: Optional[str] = None) -> List[Dict[str, Any]]:
        active_list = []
        for a in self.infrastructure_alerts:
            if not a.get("active", True):
                continue
            if emergency_vehicle_id and a.get("emergencyVehicleId") != emergency_vehicle_id:
                continue
            active_list.append(a)
        return active_list

db_store = InMemoryStore()

class DatabaseManager:
    def __init__(self):
        self.client = None
        self.db = None
        self.using_atlas = False
        self._connect()

    def _connect(self):
        if settings.MONGODB_URI and ("cluster" in settings.MONGODB_URI or "mongodb+srv" in settings.MONGODB_URI or "mongodb://" in settings.MONGODB_URI):
            try:
                from pymongo import MongoClient
                logger.info("Attempting MongoDB Atlas connection...")
                self.client = MongoClient(settings.MONGODB_URI, serverSelectionTimeoutMS=2000)
                self.client.admin.command('ping')
                self.db = self.client[settings.DB_NAME]
                self.using_atlas = True
                logger.info("Successfully connected to persistent MongoDB Atlas database!")
                return
            except Exception as e:
                logger.warning(f"[DEVELOPMENT FALLBACK — NOT LIVE PERSISTENCE] MongoDB Atlas connection error ({e}).")
        
        self.using_atlas = False
        logger.info("[DEVELOPMENT FALLBACK — NOT LIVE PERSISTENCE] In-memory non-persistent database store active.")

    def get_db_status(self) -> Dict[str, Any]:
        return {
            "usingAtlas": self.using_atlas,
            "mode": "PERSISTENT_MONGODB_ATLAS" if self.using_atlas else "DEVELOPMENT FALLBACK — NOT LIVE PERSISTENCE",
            "databaseName": settings.DB_NAME if self.using_atlas else "in_memory_dev_store"
        }

    def upsert_vehicle(self, data: Dict[str, Any]):
        if self.using_atlas and self.db is not None:
            try:
                self.db.vehicles.update_one({"vehicleId": data["vehicleId"]}, {"$set": data}, upsert=True)
            except Exception as e:
                logger.error(f"Atlas error: {e}")
        return db_store.upsert_vehicle(data)

    def update_fcm_token(self, vehicle_id: str, fcm_token: str):
        if self.using_atlas and self.db is not None:
            try:
                self.db.vehicles.update_one({"vehicleId": vehicle_id}, {"$set": {"fcmToken": fcm_token}}, upsert=True)
            except Exception as e:
                logger.error(f"Atlas error: {e}")
        return db_store.update_fcm_token(vehicle_id, fcm_token)

    def get_vehicle(self, vehicle_id: str) -> Optional[Dict[str, Any]]:
        if self.using_atlas and self.db is not None:
            try:
                v = self.db.vehicles.find_one({"vehicleId": vehicle_id}, {"_id": 0})
                if v:
                    return v
            except Exception:
                pass
        return db_store.get_vehicle(vehicle_id)

    def upsert_emergency_vehicle(self, data: Dict[str, Any]):
        if self.using_atlas and self.db is not None:
            try:
                self.db.emergency_vehicles.update_one({"vehicleId": data["vehicleId"]}, {"$set": data}, upsert=True)
            except Exception as e:
                logger.error(f"Atlas error: {e}")
        return db_store.upsert_emergency(data)

    def save_alert(self, alert_data: Dict[str, Any]):
        if "active" not in alert_data:
            alert_data["active"] = True
        if self.using_atlas and self.db is not None:
            try:
                self.db.alerts.insert_one(dict(alert_data))
            except Exception as e:
                logger.error(f"Atlas error: {e}")
        return db_store.add_alert(alert_data)

    def deactivate_alerts_for_emergency(self, emergency_vehicle_id: str):
        if self.using_atlas and self.db is not None:
            try:
                self.db.alerts.update_many(
                    {"$or": [{"emergencyVehicleId": emergency_vehicle_id}, {"active": True}]},
                    {"$set": {"active": False}}
                )
            except Exception as e:
                logger.error(f"Atlas error: {e}")
        return db_store.deactivate_alerts_for_emergency(emergency_vehicle_id)

    def deactivate_alerts_for_vehicle(self, vehicle_id: str):
        if self.using_atlas and self.db is not None:
            try:
                self.db.alerts.update_many(
                    {"vehicleId": vehicle_id},
                    {"$set": {"active": False}}
                )
            except Exception as e:
                logger.error(f"Atlas error: {e}")
        return db_store.deactivate_alerts_for_vehicle(vehicle_id)

    def save_route(self, route_data: Dict[str, Any]):
        if self.using_atlas and self.db is not None:
            try:
                self.db.routes.insert_one(dict(route_data))
            except Exception as e:
                logger.error(f"Atlas error: {e}")
        db_store.routes.append(route_data)

    def get_all_normal_vehicles(self, max_stale_seconds: Optional[float] = None) -> List[Dict[str, Any]]:
        stale_limit = max_stale_seconds if max_stale_seconds is not None else settings.GPS_STALE_TIMEOUT_SECONDS
        if self.using_atlas and self.db is not None:
            try:
                all_v = list(self.db.vehicles.find({"isEmergency": {"$ne": True}}, {"_id": 0}))
                now = datetime.now(timezone.utc)
                fresh = []
                for v in all_v:
                    ts_str = v.get("lastUpdated")
                    if ts_str:
                        try:
                            ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                            if ts.tzinfo is None:
                                ts = ts.replace(tzinfo=timezone.utc)
                            if (now - ts).total_seconds() <= stale_limit:
                                fresh.append(v)
                            continue
                        except Exception:
                            pass
                    fresh.append(v)
                return fresh
            except Exception as e:
                logger.error(f"Atlas error in get_all_normal_vehicles: {e}")
        return db_store.get_fresh_vehicles(stale_limit)

    def get_active_emergency(self) -> Optional[Dict[str, Any]]:
        return self.get_active_emergency_vehicle()

    def get_active_emergency_vehicle(self) -> Optional[Dict[str, Any]]:
        if self.using_atlas and self.db is not None:
            try:
                ev = self.db.emergency_vehicles.find_one({"emergencyActive": True}, {"_id": 0})
                if ev:
                    return ev
            except Exception:
                pass
        return db_store.get_active_emergency()

    def get_alerts_by_vehicle(self, vehicle_id: str) -> List[Dict[str, Any]]:
        if self.using_atlas and self.db is not None:
            try:
                return list(self.db.alerts.find({"vehicleId": vehicle_id}, {"_id": 0}))
            except Exception:
                pass
        return db_store.get_alerts_for_vehicle(vehicle_id)

    def get_active_alerts_by_vehicle(self, vehicle_id: str, active_emergency_id: Optional[str] = None) -> List[Dict[str, Any]]:
        if self.using_atlas and self.db is not None:
            try:
                query = {"vehicleId": vehicle_id, "active": {"$ne": False}, "action": {"$nin": ["NO_ALERT", "ACKNOWLEDGED"]}}
                if active_emergency_id:
                    query["$or"] = [{"emergencyVehicleId": active_emergency_id}, {"emergencyVehicleId": {"$exists": False}}]
                return list(self.db.alerts.find(query, {"_id": 0}))
            except Exception:
                pass
        return db_store.get_active_alerts_for_vehicle(vehicle_id, active_emergency_id)

    # Unknown Road User DB Manager methods
    def upsert_unknown_road_user(self, data: Dict[str, Any]) -> Dict[str, Any]:
        data["registrationStatus"] = "UNKNOWN"
        now_str = datetime.now(timezone.utc).isoformat()
        data["lastSeen"] = now_str
        if self.using_atlas and self.db is not None:
            try:
                self.db.unknown_road_users.update_one({"vehicleId": data["vehicleId"]}, {"$set": data}, upsert=True)
            except Exception as e:
                logger.error(f"Atlas error in upsert_unknown_road_user: {e}")
        return db_store.upsert_unknown_road_user(data)

    def get_unknown_road_user(self, vehicle_id: str) -> Optional[Dict[str, Any]]:
        if self.using_atlas and self.db is not None:
            try:
                u = self.db.unknown_road_users.find_one({"vehicleId": vehicle_id}, {"_id": 0})
                if u:
                    return u
            except Exception:
                pass
        return db_store.get_unknown_road_user(vehicle_id)

    def get_all_unknown_road_users(self) -> List[Dict[str, Any]]:
        if self.using_atlas and self.db is not None:
            try:
                return list(self.db.unknown_road_users.find({}, {"_id": 0}))
            except Exception:
                pass
        return db_store.get_all_unknown_road_users()

    def delete_unknown_road_user(self, vehicle_id: str) -> bool:
        if self.using_atlas and self.db is not None:
            try:
                self.db.unknown_road_users.delete_one({"vehicleId": vehicle_id})
                self.db.infrastructure_alerts.update_many({"vehicleId": vehicle_id}, {"$set": {"active": False}})
            except Exception as e:
                logger.error(f"Atlas error in delete_unknown_road_user: {e}")
        return db_store.delete_unknown_road_user(vehicle_id)

    # Infrastructure Alerts DB Manager methods
    def save_infrastructure_alert(self, alert_data: Dict[str, Any]) -> Dict[str, Any]:
        if self.using_atlas and self.db is not None:
            try:
                v_id = alert_data.get("vehicleId")
                ev_id = alert_data.get("emergencyVehicleId")
                self.db.infrastructure_alerts.update_many(
                    {"vehicleId": v_id, "emergencyVehicleId": ev_id},
                    {"$set": {"active": False}}
                )
                self.db.infrastructure_alerts.insert_one(dict(alert_data))
            except Exception as e:
                logger.error(f"Atlas error in save_infrastructure_alert: {e}")
        return db_store.save_infrastructure_alert(alert_data)

    def deactivate_infrastructure_alerts_for_emergency(self, emergency_vehicle_id: str):
        if self.using_atlas and self.db is not None:
            try:
                self.db.infrastructure_alerts.update_many(
                    {"emergencyVehicleId": emergency_vehicle_id},
                    {"$set": {"active": False}}
                )
            except Exception as e:
                logger.error(f"Atlas error in deactivate_infrastructure_alerts_for_emergency: {e}")
        return db_store.deactivate_infrastructure_alerts_for_emergency(emergency_vehicle_id)

    def deactivate_infrastructure_alerts_for_vehicle(self, vehicle_id: str):
        if self.using_atlas and self.db is not None:
            try:
                self.db.infrastructure_alerts.update_many(
                    {"vehicleId": vehicle_id},
                    {"$set": {"active": False}}
                )
            except Exception as e:
                logger.error(f"Atlas error in deactivate_infrastructure_alerts_for_vehicle: {e}")
        return db_store.deactivate_infrastructure_alerts_for_vehicle(vehicle_id)

    def get_active_infrastructure_alerts(self, emergency_vehicle_id: Optional[str] = None) -> List[Dict[str, Any]]:
        if self.using_atlas and self.db is not None:
            try:
                query = {"active": True}
                if emergency_vehicle_id:
                    query["emergencyVehicleId"] = emergency_vehicle_id
                return list(self.db.infrastructure_alerts.find(query, {"_id": 0}))
            except Exception:
                pass
        return db_store.get_active_infrastructure_alerts(emergency_vehicle_id)

    def clear_all(self):
        if self.using_atlas and self.db is not None:
            try:
                self.db.vehicles.delete_many({})
                self.db.emergency_vehicles.delete_many({})
                self.db.alerts.delete_many({})
                self.db.routes.delete_many({})
                self.db.traffic_data.delete_many({})
                self.db.unknown_road_users.delete_many({})
                self.db.infrastructure_alerts.delete_many({})
            except Exception as e:
                logger.error(f"Atlas error in clear_all: {e}")
        db_store.clear_all()

db = DatabaseManager()

