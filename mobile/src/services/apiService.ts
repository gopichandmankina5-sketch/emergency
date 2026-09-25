import axios from 'axios';
import { Vehicle } from '../models/vehicle';
import { CorridorAlert } from '../models/alert';
import { CorridorResult, AnalyticsSummary, SuccessCriteriaResponse } from '../models/corridor';

// Default backend URL: Uses EXPO_PUBLIC_API_URL or workstation LAN IP fallback.
// IMPORTANT: Physical phone/emulator cannot reach 127.0.0.1 or localhost.
const DEFAULT_API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://192.168.1.50:8000';

class ApiService {
  private baseUrl: string;

  constructor() {
    this.baseUrl = this.normalizeUrl(DEFAULT_API_URL);
  }

  private normalizeUrl(url: string): string {
    let clean = url.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = `http://${clean}`;
    }
    return clean.endsWith('/api') ? clean : `${clean.replace(/\/$/, '')}/api`;
  }

  public setBackendUrl(url: string) {
    this.baseUrl = this.normalizeUrl(url);
  }

  public getBackendUrl(): string {
    return this.baseUrl;
  }

  public getBaseHost(): string {
    return this.baseUrl.replace(/\/api$/, '');
  }

  async registerVehicle(
    vehicleId: string,
    isEmergency: boolean = false,
    type?: string,
    fcmToken?: string,
    lat: number = 13.0827,
    lon: number = 80.2707
  ): Promise<boolean> {
    try {
      const response = await axios.post(`${this.baseUrl}/vehicles/register`, {
        vehicleId,
        isEmergency,
        emergencyType: type,
        fcmToken: fcmToken || `mock_token_${vehicleId}`,
        latitude: lat,
        longitude: lon,
      }, { timeout: 4000 });
      return response.status === 200;
    } catch (error) {
      console.warn(`[ApiService] Register vehicle ${vehicleId} error:`, error);
      return false;
    }
  }

  async registerFCMToken(vehicleId: string, fcmToken: string): Promise<boolean> {
    try {
      const response = await axios.post(`${this.baseUrl}/vehicles/fcm-token`, {
        vehicleId,
        fcmToken,
      }, { timeout: 4000 });
      return response.status === 200;
    } catch (error) {
      console.warn(`[ApiService] Register FCM token error:`, error);
      return false;
    }
  }

  async updateVehicleLocation(params: {
    vehicleId: string;
    latitude: number;
    longitude: number;
    speed?: number;
    heading?: number;
    locationEnabled?: boolean;
  }): Promise<boolean> {
    try {
      const response = await axios.post(`${this.baseUrl}/vehicles/location`, {
        vehicleId: params.vehicleId,
        latitude: params.latitude,
        longitude: params.longitude,
        speed: params.speed ?? 0.0,
        heading: params.heading ?? 0.0,
        locationEnabled: params.locationEnabled ?? true,
        lastUpdated: new Date().toISOString(),
      }, { timeout: 4000 });
      return response.status === 200;
    } catch (error) {
      console.warn(`[ApiService] Update location error:`, error);
      return false;
    }
  }

  async startEmergency(params: {
    vehicleId: string;
    type: string;
    latitude: number;
    longitude: number;
    speed?: number;
    heading?: number;
    destLat: number;
    destLon: number;
  }): Promise<CorridorResult | null> {
    try {
      const response = await axios.post(`${this.baseUrl}/emergency/start`, {
        vehicleId: params.vehicleId,
        type: params.type,
        latitude: params.latitude,
        longitude: params.longitude,
        speed: params.speed ?? 45.0,
        heading: params.heading ?? 90.0,
        destination: { latitude: params.destLat, longitude: params.destLon },
      }, { timeout: 5000 });
      if (response.status === 200 && response.data?.corridor) {
        return response.data.corridor as CorridorResult;
      }
    } catch (error) {
      console.warn(`[ApiService] Start emergency error:`, error);
    }
    return null;
  }

  async updateEmergencyLocation(params: {
    vehicleId: string;
    latitude: number;
    longitude: number;
    speed?: number;
    heading?: number;
  }): Promise<CorridorResult | null> {
    try {
      const response = await axios.post(`${this.baseUrl}/emergency/location`, {
        vehicleId: params.vehicleId,
        latitude: params.latitude,
        longitude: params.longitude,
        speed: params.speed ?? 45.0,
        heading: params.heading ?? 90.0,
      }, { timeout: 4000 });
      if (response.status === 200 && response.data?.corridor) {
        return response.data.corridor as CorridorResult;
      }
    } catch (error) {
      console.warn(`[ApiService] Update emergency location error:`, error);
    }
    return null;
  }

  async stopEmergency(vehicleId: string = 'AMB001'): Promise<boolean> {
    try {
      const response = await axios.post(`${this.baseUrl}/emergency/stop?vehicleId=${vehicleId}`, {}, { timeout: 4000 });
      return response.status === 200;
    } catch (error) {
      console.warn(`[ApiService] Stop emergency error:`, error);
      return false;
    }
  }

  async fetchCorridor(emergencyId: string = 'AMB001'): Promise<CorridorResult | null> {
    try {
      const response = await axios.get(`${this.baseUrl}/emergency/${emergencyId}/corridor`, { timeout: 4000 });
      if (response.status === 200) {
        return response.data as CorridorResult;
      }
    } catch (error) {
      console.warn(`[ApiService] Fetch corridor error:`, error);
    }
    return null;
  }

  async fetchAlertForVehicle(vehicleId: string): Promise<CorridorAlert | null> {
    try {
      const response = await axios.get(`${this.baseUrl}/alerts/${vehicleId}`, { timeout: 4000 });
      if (response.status === 200 && response.data?.hasAlert && response.data?.latestAlert) {
        return response.data.latestAlert as CorridorAlert;
      }
    } catch (error) {
      console.warn(`[ApiService] Fetch alert error:`, error);
    }
    return null;
  }

  async fetchNearbyVehicles(radius: number = 800): Promise<Vehicle[]> {
    try {
      const response = await axios.get(`${this.baseUrl}/vehicles/nearby?radius=${radius}`, { timeout: 4000 });
      if (response.status === 200 && Array.isArray(response.data?.vehicles)) {
        return response.data.vehicles as Vehicle[];
      }
    } catch (error) {
      console.warn(`[ApiService] Fetch nearby vehicles error:`, error);
    }
    return [];
  }

  async fetchAnalyticsSummary(): Promise<AnalyticsSummary | null> {
    try {
      const response = await axios.get(`${this.baseUrl}/analytics`, { timeout: 4000 });
      if (response.status === 200) {
        return response.data as AnalyticsSummary;
      }
    } catch (error) {
      console.warn(`[ApiService] Fetch analytics summary error:`, error);
    }
    return null;
  }

  async fetchSuccessCriteria(): Promise<SuccessCriteriaResponse | null> {
    try {
      const response = await axios.get(`${this.baseUrl}/success-criteria`, { timeout: 4000 });
      if (response.status === 200) {
        return response.data as SuccessCriteriaResponse;
      }
    } catch (error) {
      console.warn(`[ApiService] Fetch success criteria error:`, error);
    }
    return null;
  }

  getCsvExportUrl(): string {
    return `${this.baseUrl}/analytics/export-csv`;
  }
}

export const apiService = new ApiService();
