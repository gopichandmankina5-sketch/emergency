from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
from app.services.corridor_service import corridor_service
from app.database.connection import db
from app.notifications.fcm_handler import fcm_handler
from app.models.schemas import AlertResponse

router = APIRouter(prefix="/alerts", tags=["Alerts"])

@router.get("/{vehicleId}")
def get_alerts_for_vehicle(vehicleId: str):
    return corridor_service.get_active_alert_response(vehicleId)

@router.post("/send")
def send_alert_manually(payload: Dict[str, Any]):
    vehicle_id = payload.get("vehicleId")
    if not vehicle_id:
        raise HTTPException(status_code=400, detail="vehicleId required")
        
    v_info = db.get_vehicle(vehicle_id)
    fcm_token = v_info.get("fcmToken") if v_info else f"mock_token_{vehicle_id}"
    
    title = payload.get("title", "🚨 EMERGENCY VEHICLE APPROACHING")
    body = payload.get("body", "MOVE LEFT WHEN SAFE")
    
    sent = fcm_handler.send_push_notification(fcm_token, title, body, payload)
    db.save_alert(payload)
    return {"status": "DISPATCHED" if sent else "FAILED", "payload": payload}

@router.post("/{vehicleId}/acknowledge")
def acknowledge_alert(vehicleId: str):
    db.save_alert({
        "vehicleId": vehicleId,
        "action": "ACKNOWLEDGED",
        "timestamp": db.utcnow_iso() if hasattr(db, 'utcnow_iso') else ""
    })
    return {"status": "SUCCESS", "vehicleId": vehicleId, "acknowledged": True}
