import { apiService } from './apiService';
import { CorridorResult } from '../models/corridor';

export interface EmergencyParams {
  vehicleId: string;
  type: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  destLat: number;
  destLon: number;
}

class EmergencyService {
  async startEmergency(params: EmergencyParams): Promise<CorridorResult | null> {
    // Register emergency vehicle first
    await apiService.registerVehicle(
      params.vehicleId,
      true,
      params.type,
      `mock_fcm_${params.vehicleId}`,
      params.latitude,
      params.longitude
    );

    return await apiService.startEmergency(params);
  }

  async updateTelemetry(params: {
    vehicleId: string;
    latitude: number;
    longitude: number;
    speed: number;
    heading: number;
  }): Promise<CorridorResult | null> {
    return await apiService.updateEmergencyLocation(params);
  }

  async stopEmergency(vehicleId: string = 'AMB001'): Promise<boolean> {
    return await apiService.stopEmergency(vehicleId);
  }

  async getCorridor(vehicleId: string = 'AMB001'): Promise<CorridorResult | null> {
    return await apiService.fetchCorridor(vehicleId);
  }
}

export const emergencyService = new EmergencyService();
