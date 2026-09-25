import logging
from flask import Blueprint, request, jsonify
from datetime import datetime, timezone

from app.database.connection import db
from app.services.corridor_service import corridor_service

logger = logging.getLogger("road_users_route")

road_users_bp = Blueprint("road_users", __name__)

@road_users_bp.route("/api/road-users/observe", methods=["POST", "OPTIONS"])
def observe_road_user():
    if request.method == "OPTIONS":
        return jsonify({"status": "OK"})
    
    payload = request.get_json() or {}
    v_id = payload.get("vehicleId")
    if not v_id:
        return jsonify({"error": "BAD_REQUEST", "message": "vehicleId required"}), 400

    data = {
        "vehicleId": v_id,
        "registrationStatus": "UNKNOWN",
        "latitude": float(payload.get("latitude", 13.0800)),
        "longitude": float(payload.get("longitude", 80.2690)),
        "speed": float(payload.get("speed", 0.0)),
        "heading": float(payload.get("heading", 90.0)),
        "vehicleType": payload.get("vehicleType", "CAR"),
        "lastSeen": datetime.now(timezone.utc).isoformat()
    }

    saved = db.upsert_unknown_road_user(data)

    active_ev = db.get_active_emergency_vehicle()
    if active_ev:
        corridor_service.recalculate_and_dispatch(active_ev["vehicleId"])

    return jsonify(saved), 200

@road_users_bp.route("/api/road-users", methods=["GET"])
def list_road_users():
    users = db.get_all_unknown_road_users()
    return jsonify(users), 200

@road_users_bp.route("/api/road-users/<vehicle_id>", methods=["DELETE", "OPTIONS"])
def delete_road_user(vehicle_id):
    if request.method == "OPTIONS":
        return jsonify({"status": "OK"})

    deleted = db.delete_unknown_road_user(vehicle_id)
    active_ev = db.get_active_emergency_vehicle()
    if active_ev:
        corridor_service.recalculate_and_dispatch(active_ev["vehicleId"])

    return jsonify({
        "status": "DELETED" if deleted else "NOT_FOUND",
        "vehicleId": vehicle_id
    }), 200 if deleted else 404

@road_users_bp.route("/api/road-users/simulate", methods=["POST", "OPTIONS"])
def simulate_road_user():
    if request.method == "OPTIONS":
        return jsonify({"status": "OK"})

    payload = request.get_json() or {}
    v_id = payload.get("vehicleId")
    if not v_id:
        return jsonify({"error": "BAD_REQUEST", "message": "vehicleId required"}), 400

    existing = db.get_unknown_road_user(v_id) or {}
    data = {
        "vehicleId": v_id,
        "registrationStatus": "UNKNOWN",
        "latitude": float(payload.get("latitude", existing.get("latitude", 13.0800))),
        "longitude": float(payload.get("longitude", existing.get("longitude", 80.2690))),
        "speed": float(payload.get("speed", existing.get("speed", 0.0))),
        "heading": float(payload.get("heading", existing.get("heading", 90.0))),
        "vehicleType": payload.get("vehicleType", existing.get("vehicleType", "CAR")),
        "lastSeen": datetime.now(timezone.utc).isoformat()
    }

    saved = db.upsert_unknown_road_user(data)

    active_ev = db.get_active_emergency_vehicle()
    if active_ev:
        corridor_service.recalculate_and_dispatch(active_ev["vehicleId"])

    return jsonify(saved), 200

@road_users_bp.route("/api/infrastructure/alerts", methods=["GET"])
def get_infrastructure_alerts():
    ev_id = request.args.get("emergencyVehicleId", "AMB001")
    alerts = db.get_active_infrastructure_alerts(ev_id)
    return jsonify(alerts), 200
