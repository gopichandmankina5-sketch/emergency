import React, { createContext, useContext, useState, useEffect, useRef } from 'react';
import { CorridorResult } from '../models/corridor';
import { Vehicle } from '../models/vehicle';
import { emergencyService } from '../services/emergencyService';
import { apiService } from '../services/apiService';
import { locationService } from '../services/locationService';
import { useConnectionStatus, ConnectionStatus } from '../hooks/useConnectionStatus';

interface EmergencyContextType {
  isEmergencyActive: boolean;
  emergencyVehicleId: string;
  emergencyType: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  destLat: number;
  destLon: number;
  activeCorridor: CorridorResult | null;
  nearbyVehicles: Vehicle[];
  isLiveGpsMode: boolean;
  connectionStatus: ConnectionStatus;
  setEmergencyType: (type: string) => void;
  setDestination: (lat: number, lon: number) => void;
  toggleLiveGpsMode: (enabled: boolean) => void;
  startEmergencyMission: () => Promise<void>;
  stopEmergencyMission: () => Promise<void>;
}

const EmergencyContext = createContext<EmergencyContextType | null>(null);

export const EmergencyProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [isEmergencyActive, setIsEmergencyActive] = useState<boolean>(false);
  const [emergencyVehicleId] = useState<string>('AMB001');
  const [emergencyType, setEmergencyType] = useState<string>('AMBULANCE');
  const [latitude, setLatitude] = useState<number>(13.0800);
  const [longitude, setLongitude] = useState<number>(80.2680);
  const [speed, setSpeed] = useState<number>(45.0);
  const [heading, setHeading] = useState<number>(90.0);
  const [destLat, setDestLat] = useState<number>(13.1000);
  const [destLon, setDestLon] = useState<number>(80.3000);
  const [activeCorridor, setActiveCorridor] = useState<CorridorResult | null>(null);
  const [nearbyVehicles, setNearbyVehicles] = useState<Vehicle[]>([]);
  const [isLiveGpsMode, setIsLiveGpsMode] = useState<boolean>(true);

  const connectionStatus = useConnectionStatus();
  const telemetryTimerRef = useRef<NodeJS.Timeout | null>(null);

  const setDestination = (lat: number, lon: number) => {
    setDestLat(lat);
    setDestLon(lon);
  };

  const toggleLiveGpsMode = (enabled: boolean) => {
    setIsLiveGpsMode(enabled);
  };

  const startEmergencyMission = async () => {
    setIsEmergencyActive(true);

    let currentLat = latitude;
    let currentLon = longitude;
    let currentSpeed = speed;
    let currentHeading = heading;

    if (isLiveGpsMode) {
      const loc = await locationService.getCurrentLocation();
      if (loc) {
        currentLat = loc.latitude;
        currentLon = loc.longitude;
        currentSpeed = loc.speed;
        currentHeading = loc.heading;
        setLatitude(loc.latitude);
        setLongitude(loc.longitude);
        setSpeed(loc.speed);
        setHeading(loc.heading);
        connectionStatus.setGpsStale(loc.isStale);
      }
    }

    const corridor = await emergencyService.startEmergency({
      vehicleId: emergencyVehicleId,
      type: emergencyType,
      latitude: currentLat,
      longitude: currentLon,
      speed: currentSpeed,
      heading: currentHeading,
      destLat,
      destLon,
    });

    if (corridor) {
      setActiveCorridor(corridor);
      connectionStatus.recordSuccess();
    } else {
      connectionStatus.recordFailure();
    }

    // Start 2-second telemetry loop
    if (telemetryTimerRef.current) clearInterval(telemetryTimerRef.current);

    telemetryTimerRef.current = setInterval(async () => {
      let updateLat = currentLat;
      let updateLon = currentLon;
      let updateSpeed = currentSpeed;
      let updateHeading = currentHeading;

      if (isLiveGpsMode) {
        const loc = await locationService.getCurrentLocation();
        if (loc) {
          updateLat = loc.latitude;
          updateLon = loc.longitude;
          updateSpeed = loc.speed;
          updateHeading = loc.heading;
          setLatitude(loc.latitude);
          setLongitude(loc.longitude);
          setSpeed(loc.speed);
          setHeading(loc.heading);
          connectionStatus.setGpsStale(loc.isStale);
        }
      } else {
        // Incrementally simulate forward movement if not in live GPS mode
        updateLat += 0.0003;
        updateLon += 0.0003;
        setLatitude(updateLat);
        setLongitude(updateLon);
      }

      currentLat = updateLat;
      currentLon = updateLon;

      const updatedCorridor = await emergencyService.updateTelemetry({
        vehicleId: emergencyVehicleId,
        latitude: updateLat,
        longitude: updateLon,
        speed: updateSpeed,
        heading: updateHeading,
      });

      if (updatedCorridor) {
        setActiveCorridor(updatedCorridor);
        connectionStatus.recordSuccess();
      } else {
        connectionStatus.recordFailure();
      }

      const nearby = await apiService.fetchNearbyVehicles();
      setNearbyVehicles(nearby);
    }, 2000);
  };

  const stopEmergencyMission = async () => {
    setIsEmergencyActive(false);
    if (telemetryTimerRef.current) {
      clearInterval(telemetryTimerRef.current);
      telemetryTimerRef.current = null;
    }
    await emergencyService.stopEmergency(emergencyVehicleId);
  };

  useEffect(() => {
    return () => {
      if (telemetryTimerRef.current) clearInterval(telemetryTimerRef.current);
    };
  }, []);

  return (
    <EmergencyContext.Provider
      value={{
        isEmergencyActive,
        emergencyVehicleId,
        emergencyType,
        latitude,
        longitude,
        speed,
        heading,
        destLat,
        destLon,
        activeCorridor,
        nearbyVehicles,
        isLiveGpsMode,
        connectionStatus,
        setEmergencyType,
        setDestination,
        toggleLiveGpsMode,
        startEmergencyMission,
        stopEmergencyMission,
      }}
    >
      {children}
    </EmergencyContext.Provider>
  );
};

export const useEmergency = () => {
  const context = useContext(EmergencyContext);
  if (!context) throw new Error('useEmergency must be used within an EmergencyProvider');
  return context;
};
