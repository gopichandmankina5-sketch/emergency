from flask import Blueprint, jsonify, request
from app.services.corridor_service import corridor_service
from app.database.connection import db

vehicles_bp = Blueprint("vehicles", __name__)

@vehicles_bp.route("/api/vehicles/register", methods=["POST", "OPTIONS"])
def register_vehicle():
    if request.method == "OPTIONS": return jsonify({"status": "OK"})
    payload = request.get_json() or {}
    v_id = payload.get("vehicleId", "UNKNOWN")
    from datetime import datetime, timezone
    data = {
        "vehicleId": v_id,
        "isEmergency": payload.get("isEmergency", False),
        "emergencyType": payload.get("emergencyType"),
        "fcmToken": payload.get("fcmToken") or f"mock_token_{v_id}",
        "locationEnabled": payload.get("locationEnabled", True),
        "latitude": payload.get("latitude", 13.0827),
        "longitude": payload.get("longitude", 80.2707),
        "speed": payload.get("speed", 0.0),
        "heading": payload.get("heading", 0.0),
        "lastUpdated": datetime.now(timezone.utc).isoformat()
    }
    db.upsert_vehicle(data)
    return jsonify({"status": "SUCCESS", "message": f"Vehicle {v_id} registered", "data": data})

@vehicles_bp.route("/api/vehicles/fcm-token", methods=["POST", "OPTIONS"])
def register_fcm_token():
    if request.method == "OPTIONS": return jsonify({"status": "OK"})
    payload = request.get_json() or {}
    v_id = payload.get("vehicleId")
    token = payload.get("fcmToken")
    if not v_id or not token:
        return jsonify({"error": "BAD_REQUEST", "message": "vehicleId and fcmToken required"}), 400
    res = corridor_service.register_fcm_token(v_id, token)
    return jsonify(res)

@vehicles_bp.route("/api/vehicles/location", methods=["POST", "OPTIONS"])
def update_vehicle_location():
    if request.method == "OPTIONS": return jsonify({"status": "OK"})
    payload = request.get_json() or {}
    from datetime import datetime, timezone
    if not payload.get("lastUpdated"):
        payload["lastUpdated"] = datetime.now(timezone.utc).isoformat()
    corridor_service.update_vehicle_location(payload)
    return jsonify({"status": "SUCCESS", "vehicleId": payload.get("vehicleId"), "receivedAt": payload.get("lastUpdated")})

@vehicles_bp.route("/api/vehicles/nearby", methods=["GET"])
def get_nearby_vehicles():
    radius = float(request.args.get("radius", 800.0))
    lat_val = request.args.get("latitude")
    lon_val = request.args.get("longitude")
    stale_val = request.args.get("stale_seconds")

    lat = float(lat_val) if lat_val is not None else None
    lon = float(lon_val) if lon_val is not None else None
    max_stale = float(stale_val) if stale_val is not None else None

    vehicles = corridor_service.get_nearby_vehicles(
        max_radius_m=radius,
        lat=lat,
        lon=lon,
        max_stale_seconds=max_stale
    )
    return jsonify({"count": len(vehicles), "vehicles": vehicles})
