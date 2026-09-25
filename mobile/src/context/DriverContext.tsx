import React, { createContext, useContext, useState, useEffect, useRef } from 'react';
import { CorridorAlert } from '../models/alert';
import { vehicleService } from '../services/vehicleService';
import { apiService } from '../services/apiService';
import { locationService } from '../services/locationService';
import { notificationService } from '../services/notificationService';
import { useConnectionStatus, ConnectionStatus } from '../hooks/useConnectionStatus';

interface DriverContextType {
  vehicleId: string;
  locationEnabled: boolean;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  activeAlert: CorridorAlert | null;
  connectionStatus: ConnectionStatus;
  setVehicleId: (id: string) => Promise<void>;
  toggleLocationPermission: (enabled: boolean) => Promise<void>;
}

const DriverContext = createContext<DriverContextType | null>(null);

export const DriverProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [vehicleId, setVehicleIdState] = useState<string>('V102');
  const [locationEnabled, setLocationEnabled] = useState<boolean>(true);
  const [latitude, setLatitude] = useState<number>(13.0827);
  const [longitude, setLongitude] = useState<number>(80.2707);
  const [speed, setSpeed] = useState<number>(32.0);
  const [heading, setHeading] = useState<number>(90.0);
  const [activeAlert, setActiveAlert] = useState<CorridorAlert | null>(null);

  const connectionStatus = useConnectionStatus();
  const pollingTimerRef = useRef<NodeJS.Timeout | null>(null);

  const setVehicleId = async (id: string) => {
    setVehicleIdState(id);
    await vehicleService.setVehicleId(id);
    await vehicleService.initializeDriverVehicle(id);
  };

  const toggleLocationPermission = async (enabled: boolean) => {
    setLocationEnabled(enabled);

    if (enabled) {
      const granted = await locationService.requestPermission();
      if (!granted) {
        setLocationEnabled(false);
        return;
      }
    }

    // Immediately send location status update to backend
    await apiService.updateVehicleLocation({
      vehicleId,
      latitude,
      longitude,
      speed,
      heading,
      locationEnabled: enabled,
    });
  };

  useEffect(() => {
    let isMounted = true;

    async function init() {
      const id = await vehicleService.initializeDriverVehicle();
      if (isMounted) setVehicleIdState(id);

      // Check initial location permission
      const hasLocPermission = await locationService.requestPermission();
      if (isMounted) setLocationEnabled(hasLocPermission);

      // Start 2-second telemetry and alert polling loop
      pollingTimerRef.current = setInterval(async () => {
        if (!isMounted) return;

        let curLat = latitude;
        let curLon = longitude;
        let curSpeed = speed;
        let curHeading = heading;
        let isLocOn = locationEnabled;

        if (isLocOn) {
          const loc = await locationService.getCurrentLocation();
          if (loc) {
            curLat = loc.latitude;
            curLon = loc.longitude;
            curSpeed = loc.speed;
            curHeading = loc.heading;
            setLatitude(loc.latitude);
            setLongitude(loc.longitude);
            setSpeed(loc.speed);
            setHeading(loc.heading);
            connectionStatus.setGpsStale(loc.isStale);
          } else {
            // Location could not be fetched
            connectionStatus.setGpsStale(true);
          }
        }

        // Send telemetry update to POST /api/vehicles/location
        const success = await apiService.updateVehicleLocation({
          vehicleId: id,
          latitude: curLat,
          longitude: curLon,
          speed: curSpeed,
          heading: curHeading,
          locationEnabled: isLocOn,
        });

        if (success) {
          connectionStatus.recordSuccess();
        } else {
          connectionStatus.recordFailure();
        }

        // Fetch alert from GET /api/alerts/{vehicleId}
        const alert = await apiService.fetchAlertForVehicle(id);
        if (alert) {
          setActiveAlert(alert);
          if (isLocOn) {
            await notificationService.triggerAlertFeedback(alert);
          }
        } else {
          setActiveAlert(null);
        }
      }, 2000);
    }

    init();

    return () => {
      isMounted = false;
      if (pollingTimerRef.current) clearInterval(pollingTimerRef.current);
    };
  }, []);

  return (
    <DriverContext.Provider
      value={{
        vehicleId,
        locationEnabled,
        latitude,
        longitude,
        speed,
        heading,
        activeAlert,
        connectionStatus,
        setVehicleId,
        toggleLocationPermission,
      }}
    >
      {children}
    </DriverContext.Provider>
  );
};

export const useDriver = () => {
  const context = useContext(DriverContext);
  if (!context) throw new Error('useDriver must be used within a DriverProvider');
  return context;
};
