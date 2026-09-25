import os
import csv
import io
import time
import logging
from flask import Flask, request, jsonify, send_from_directory, Response
from datetime import datetime

from app.config import settings
from app.database.connection import db
from app.services.corridor_service import corridor_service
from app.notifications.fcm_handler import fcm_handler
from app.routes.analytics import analytics_bp
from app.routes.vehicles import vehicles_bp
from app.routes.road_users import road_users_bp

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("main")

app = Flask(__name__, static_folder="../../static", static_url_path="/static")
app.register_blueprint(analytics_bp)
app.register_blueprint(vehicles_bp)
app.register_blueprint(road_users_bp)

# Timer & CORS Middleware
@app.before_request
def start_timer():
    request.start_time = time.perf_counter()

@app.after_request
def add_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization'
    response.headers['Access-Control-Allow-Methods'] = 'GET,POST,OPTIONS'
    
    if hasattr(request, 'start_time'):
        duration_ms = round((time.perf_counter() - request.start_time) * 1000.0, 2)
        response.headers['X-Response-Time-Ms'] = str(duration_ms)
    return response

@app.route("/", methods=["GET"])
def index():
    return send_from_directory("../../static", "index.html")

# --- Emergency & Alerts REST APIs ---

@app.route("/api/emergency/start", methods=["POST", "OPTIONS"])
def start_emergency():
    if request.method == "OPTIONS": return jsonify({"status": "OK"})
    payload = request.get_json() or {}
    if not payload.get("vehicleId") or not payload.get("destination"):
        return jsonify({"error": "BAD_REQUEST", "message": "vehicleId and destination required"}), 400
    result = corridor_service.start_emergency(payload)
    return jsonify({"status": "ACTIVE", "emergencyVehicleId": payload.get("vehicleId"), "corridor": result})

@app.route("/api/emergency/location", methods=["POST", "OPTIONS"])
def update_emergency_location():
    if request.method == "OPTIONS": return jsonify({"status": "OK"})
    payload = request.get_json() or {}
    result = corridor_service.update_emergency_location(payload)
    return jsonify({"status": "UPDATED", "emergencyVehicleId": payload.get("vehicleId"), "corridor": result})

@app.route("/api/emergency/stop", methods=["POST", "OPTIONS"])
def stop_emergency():
    if request.method == "OPTIONS": return jsonify({"status": "OK"})
    vehicle_id = request.args.get("vehicleId") or (request.get_json() or {}).get("vehicleId", "AMB001")
    res = corridor_service.stop_emergency(vehicle_id)
    return jsonify(res)

@app.route("/api/emergency/<id>/corridor", methods=["GET"])
def get_emergency_corridor(id):
    corridor = corridor_service.get_corridor(id)
    if not corridor or not corridor.get("active", False):
        return jsonify({"active": False, "message": f"No active corridor for {id}"}), 404
    return jsonify(corridor)

@app.route("/api/alerts/<vehicle_id>/acknowledge", methods=["POST", "OPTIONS"])
def acknowledge_alert(vehicle_id):
    if request.method == "OPTIONS": return jsonify({"status": "OK"})
    db.save_alert({
        "vehicleId": vehicle_id,
        "action": "ACKNOWLEDGED",
        "active": False,
        "timestamp": datetime.utcnow().isoformat()
    })
    db.deactivate_alerts_for_vehicle(vehicle_id)
    return jsonify({"status": "SUCCESS", "vehicleId": vehicle_id, "acknowledged": True})

@app.route("/api/alerts/<vehicle_id>", methods=["GET"])
def get_alerts_for_vehicle(vehicle_id):
    return jsonify(corridor_service.get_active_alert_response(vehicle_id))

@app.route("/api/alerts/send", methods=["POST", "OPTIONS"])
def send_alert_manually():
    if request.method == "OPTIONS": return jsonify({"status": "OK"})
    payload = request.get_json() or {}
    vehicle_id = payload.get("vehicleId")
    if not vehicle_id:
        return jsonify({"error": "BAD_REQUEST", "message": "vehicleId required"}), 400
    v_info = db.get_vehicle(vehicle_id)
    fcm_token = v_info.get("fcmToken") if v_info else f"mock_token_{vehicle_id}"
    sent = fcm_handler.send_push_notification(fcm_token, payload.get("title", "ALERT"), payload.get("body", "MANEUVER"), payload)
    db.save_alert(payload)
    return jsonify({"status": "DISPATCHED" if sent else "FAILED", "fcmMode": fcm_handler.get_status()["mode"], "payload": payload})

# WSGI to ASGI adapter for uvicorn compatibility
try:
    from a2wsgi import WSGIMiddleware
    asgi_app = WSGIMiddleware(app)
except Exception:
    asgi_app = app

if __name__ == "__main__":
    logger.info("Starting Dynamic Emergency Corridor System Backend on http://0.0.0.0:8000 ...")
    app.run(host="0.0.0.0", port=8000, debug=True)

