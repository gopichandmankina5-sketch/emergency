import math
from typing import List, Dict, Any

class LocationService:
    @staticmethod
    def haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        R = 6371000.0  # Earth radius in meters
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = (math.sin(dlat / 2) ** 2 +
             math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c

    @staticmethod
    def filter_nearby(center_lat: float, center_lon: float, vehicles: List[Dict[str, Any]], max_radius_m: float = 800.0) -> List[Dict[str, Any]]:
        nearby = []
        for v in vehicles:
            d = LocationService.haversine(center_lat, center_lon, v.get("latitude", 0), v.get("longitude", 0))
            if d <= max_radius_m:
                v_copy = dict(v)
                v_copy["distanceToEmergency"] = round(d, 1)
                nearby.append(v_copy)
        return nearby

location_service = LocationService()
