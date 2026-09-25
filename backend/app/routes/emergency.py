from fastapi import APIRouter, HTTPException
from app.models.schemas import EmergencyVehicleStart, EmergencyLocationUpdate
from app.services.corridor_service import corridor_service

router = APIRouter(prefix="/emergency", tags=["Emergency Vehicles"])

@router.post("/start")
def start_emergency(payload: EmergencyVehicleStart):
    result = corridor_service.start_emergency(payload.dict())
    return {"status": "ACTIVE", "emergencyVehicleId": payload.vehicleId, "corridor": result}

@router.post("/location")
def update_emergency_location(payload: EmergencyLocationUpdate):
    result = corridor_service.update_emergency_location(payload.dict())
    return {"status": "UPDATED", "emergencyVehicleId": payload.vehicleId, "corridor": result}

@router.post("/stop")
def stop_emergency(vehicleId: str):
    res = corridor_service.stop_emergency(vehicleId)
    return res

@router.get("/{id}/corridor")
def get_emergency_corridor(id: str):
    corridor = corridor_service.get_corridor(id)
    if not corridor or not corridor.get("active", False):
        raise HTTPException(status_code=404, detail=f"No active corridor found for emergency vehicle {id}")
    return corridor
