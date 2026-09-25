from dataclasses import dataclass, field, asdict
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

class EmergencyType(str, Enum):
    AMBULANCE = "AMBULANCE"
    FIRE = "FIRE"
    POLICE = "POLICE"

class ActionType(str, Enum):
    MOVE_LEFT = "MOVE_LEFT"
    MOVE_RIGHT = "MOVE_RIGHT"
    SLOW_DOWN = "SLOW_DOWN"
    STAY = "STAY"
    NO_ALERT = "NO_ALERT"

class AlertType(str, Enum):
    PERSONALIZED = "PERSONALIZED"
    GENERAL = "GENERAL"

@dataclass
class LatLng:
    latitude: float
    longitude: float

    def to_dict(self):
        return asdict(self)

@dataclass
class VehicleLocationUpdate:
    vehicleId: str
    latitude: float
    longitude: float
    speed: float = 0.0
    heading: float = 0.0
    locationEnabled: bool = True
    fcmToken: Optional[str] = None
    lastUpdated: Optional[str] = None

    def dict(self):
        return asdict(self)

@dataclass
class FCMTokenRegister:
    vehicleId: str
    fcmToken: str

    def dict(self):
        return asdict(self)

@dataclass
class EmergencyVehicleStart:
    vehicleId: str
    type: str
    latitude: float
    longitude: float
    destination: LatLng
    speed: float = 0.0
    heading: float = 0.0

    def dict(self):
        d = asdict(self)
        if isinstance(self.destination, LatLng):
            d["destination"] = self.destination.to_dict()
        return d

@dataclass
class AlertResponse:
    vehicleId: str
    emergencyVehicleId: str
    action: ActionType
    actionText: str
    distance: float
    eta: float
    alertType: AlertType
    timestamp: str
    status: str = "SENT"

    def dict(self):
        d = asdict(self)
        if isinstance(self.action, ActionType):
            d["action"] = self.action.value
        if isinstance(self.alertType, AlertType):
            d["alertType"] = self.alertType.value
        return d

@dataclass
class CorridorCalculationResult:
    emergencyVehicleId: str
    active: bool
    predictedRoute: List[Dict[str, float]]
    corridorPolygon: List[Dict[str, float]]
    totalNearbyVehicles: int
    obstructingVehiclesCount: int
    instructedToMoveCount: int
    alerts: List[AlertResponse]
    corridorScore: float
    timestamp: str

    def dict(self):
        d = asdict(self)
        d["alerts"] = [a.dict() if hasattr(a, "dict") else a for a in self.alerts]
        return d
