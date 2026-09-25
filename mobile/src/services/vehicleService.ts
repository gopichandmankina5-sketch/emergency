import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiService } from './apiService';
import { notificationService } from './notificationService';

const VEHICLE_ID_STORAGE_KEY = '@emergency_corridor_vehicle_id';

class VehicleService {
  private currentVehicleId: string = 'V102';

  async getOrGenerateVehicleId(): Promise<string> {
    try {
      const storedId = await AsyncStorage.getItem(VEHICLE_ID_STORAGE_KEY);
      if (storedId) {
        this.currentVehicleId = storedId;
        return storedId;
      }
      // Generate anonymous vehicle ID e.g. V102, V103...
      const randomNum = Math.floor(100 + Math.random() * 900);
      const newId = `V${randomNum}`;
      await AsyncStorage.setItem(VEHICLE_ID_STORAGE_KEY, newId);
      this.currentVehicleId = newId;
      return newId;
    } catch (e) {
      console.warn('[VehicleService] Storage error, fallback vehicle ID:', e);
      return this.currentVehicleId;
    }
  }

  async setVehicleId(id: string): Promise<void> {
    this.currentVehicleId = id;
    try {
      await AsyncStorage.setItem(VEHICLE_ID_STORAGE_KEY, id);
    } catch (e) {
      console.warn('[VehicleService] Save vehicle ID error:', e);
    }
  }

  getVehicleId(): string {
    return this.currentVehicleId;
  }

  async initializeDriverVehicle(vehicleId?: string): Promise<string> {
    const id = vehicleId || await this.getOrGenerateVehicleId();
    await apiService.registerVehicle(id, false);

    // Register FCM Token
    const token = await notificationService.registerForPushNotificationsAsync();
    if (token) {
      await apiService.registerFCMToken(id, token);
    }

    return id;
  }
}

export const vehicleService = new VehicleService();
