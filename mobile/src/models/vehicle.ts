export interface LatLngData {
  latitude: number;
  longitude: number;
}

export interface Vehicle {
  vehicleId: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  locationEnabled: boolean;
  isEmergency: boolean;
  emergencyType?: string;
  lastUpdated?: string;
}

export interface EmergencyVehicle extends Vehicle {
  emergencyActive: boolean;
  destination: LatLngData;
}
