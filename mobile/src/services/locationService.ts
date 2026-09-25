import * as Location from 'expo-location';

export interface LocationData {
  latitude: number;
  longitude: number;
  speed: number; // km/h
  heading: number; // degrees
  timestamp: number; // ms epoch
  accuracy?: number | null;
  isStale: boolean;
}

class LocationService {
  private subscription: Location.LocationSubscription | null = null;
  private lastLocation: LocationData | null = null;

  async requestPermission(): Promise<boolean> {
    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      return status === 'granted';
    } catch (error) {
      console.warn('[LocationService] Permission error:', error);
      return false;
    }
  }

  async getCurrentLocation(): Promise<LocationData | null> {
    try {
      const hasPermission = await this.requestPermission();
      if (!hasPermission) return null;

      const location = await Location.getCurrentPositionAsync({
        accuracy: Location.Accuracy.High,
      });

      const speedKmh = location.coords.speed ? Math.max(0, location.coords.speed * 3.6) : 0;
      const heading = location.coords.heading && location.coords.heading >= 0 ? location.coords.heading : 0;
      const now = Date.now();

      const data: LocationData = {
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
        speed: Math.round(speedKmh * 10) / 10,
        heading: Math.round(heading * 10) / 10,
        timestamp: location.timestamp || now,
        accuracy: location.coords.accuracy,
        isStale: (now - (location.timestamp || now)) > 5000,
      };

      this.lastLocation = data;
      return data;
    } catch (error) {
      console.warn('[LocationService] Get location error:', error);
      return null;
    }
  }

  async startLocationUpdates(
    onLocationUpdate: (data: LocationData) => void,
    intervalMs: number = 2000
  ): Promise<boolean> {
    const hasPermission = await this.requestPermission();
    if (!hasPermission) return false;

    this.stopLocationUpdates();

    try {
      this.subscription = await Location.watchPositionAsync(
        {
          accuracy: Location.Accuracy.High,
          timeInterval: intervalMs,
          distanceInterval: 1, // 1 meter movement trigger
        },
        (location) => {
          const speedKmh = location.coords.speed ? Math.max(0, location.coords.speed * 3.6) : 0;
          const heading = location.coords.heading && location.coords.heading >= 0 ? location.coords.heading : 0;
          const now = Date.now();

          const data: LocationData = {
            latitude: location.coords.latitude,
            longitude: location.coords.longitude,
            speed: Math.round(speedKmh * 10) / 10,
            heading: Math.round(heading * 10) / 10,
            timestamp: location.timestamp || now,
            accuracy: location.coords.accuracy,
            isStale: (now - (location.timestamp || now)) > 5000,
          };

          this.lastLocation = data;
          onLocationUpdate(data);
        }
      );
      return true;
    } catch (error) {
      console.warn('[LocationService] Watch position error:', error);
      return false;
    }
  }

  stopLocationUpdates() {
    if (this.subscription) {
      this.subscription.remove();
      this.subscription = null;
    }
  }

  getLastLocation(): LocationData | null {
    if (!this.lastLocation) return null;
    const now = Date.now();
    return {
      ...this.lastLocation,
      isStale: (now - this.lastLocation.timestamp) > 5000,
    };
  }
}

export const locationService = new LocationService();
