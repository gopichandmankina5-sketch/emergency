import React, { createContext, useContext, useState, useEffect, useRef } from 'react';
import { CorridorResult } from '../models/corridor';
import { Vehicle } from '../models/vehicle';
import { apiService } from '../services/apiService';
import { useConnectionStatus, ConnectionStatus } from '../hooks/useConnectionStatus';

interface SimulationContextType {
  isSimulationRunning: boolean;
  trafficDensityCount: number;
  emergencySpeedKmh: number;
  corridorResult: CorridorResult | null;
  simulatedVehicles: Vehicle[];
  connectionStatus: ConnectionStatus;
  setTrafficDensity: (count: number) => void;
  setEmergencySpeed: (speed: number) => void;
  runEmergencySimulation: () => Promise<void>;
  stopSimulation: () => void;
}

const SimulationContext = createContext<SimulationContextType | null>(null);

export const SimulationProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [isSimulationRunning, setIsSimulationRunning] = useState<boolean>(false);
  const [trafficDensityCount, setTrafficDensityCount] = useState<number>(15);
  const [emergencySpeedKmh, setEmergencySpeedKmh] = useState<number>(50.0);
  const [corridorResult, setCorridorResult] = useState<CorridorResult | null>(null);
  const [simulatedVehicles, setSimulatedVehicles] = useState<Vehicle[]>([]);

  const connectionStatus = useConnectionStatus();
  const simTimerRef = useRef<NodeJS.Timeout | null>(null);

  const setTrafficDensity = (count: number) => setTrafficDensityCount(count);
  const setEmergencySpeed = (speed: number) => setEmergencySpeedKmh(speed);

  const runEmergencySimulation = async () => {
    setIsSimulationRunning(true);

    // 1. Register AMB001
    await apiService.registerVehicle('AMB001', true, 'AMBULANCE', 'mock_token_AMB001', 13.0800, 80.2680);

    // 2. Register demo vehicles V101..V106
    const demoVehicles = [
      { id: 'V101', lat: 13.0850, lon: 80.2650, speed: 35.0, heading: 90.0 },
      { id: 'V102', lat: 13.0815, lon: 80.2695, speed: 32.0, heading: 90.0 },
      { id: 'V103', lat: 13.0818, lon: 80.2698, speed: 30.0, heading: 90.0 },
      { id: 'V104', lat: 13.0820, lon: 80.2700, speed: 28.0, heading: 90.0 },
      { id: 'V105', lat: 13.0825, lon: 80.2710, speed: 45.0, heading: 270.0 },
      { id: 'V106', lat: 13.0830, lon: 80.2715, speed: 25.0, heading: 90.0 },
    ];

    for (const dv of demoVehicles) {
      await apiService.registerVehicle(dv.id, false, undefined, `mock_token_${dv.id}`, dv.lat, dv.lon);
      await apiService.updateVehicleLocation({
        vehicleId: dv.id,
        latitude: dv.lat,
        longitude: dv.lon,
        speed: dv.speed,
        heading: dv.heading,
        locationEnabled: true,
      });
    }

    // 3. Start Emergency Corridor Calculation
    const result = await apiService.startEmergency({
      vehicleId: 'AMB001',
      type: 'AMBULANCE',
      latitude: 13.0800,
      longitude: 80.2680,
      speed: emergencySpeedKmh,
      heading: 90.0,
      destLat: 13.1000,
      destLon: 80.3000,
    });

    if (result) {
      setCorridorResult(result);
      connectionStatus.recordSuccess();
    } else {
      connectionStatus.recordFailure();
    }

    // 4. Start 2-second periodic polling for simulation updates
    if (simTimerRef.current) clearInterval(simTimerRef.current);
    simTimerRef.current = setInterval(async () => {
      const corridor = await apiService.fetchCorridor('AMB001');
      if (corridor) {
        setCorridorResult(corridor);
        connectionStatus.recordSuccess();
      } else {
        connectionStatus.recordFailure();
      }

      const vehicles = await apiService.fetchNearbyVehicles();
      setSimulatedVehicles(vehicles);
    }, 2000);
  };

  const stopSimulation = () => {
    setIsSimulationRunning(false);
    if (simTimerRef.current) {
      clearInterval(simTimerRef.current);
      simTimerRef.current = null;
    }
  };

  useEffect(() => {
    return () => {
      if (simTimerRef.current) clearInterval(simTimerRef.current);
    };
  }, []);

  return (
    <SimulationContext.Provider
      value={{
        isSimulationRunning,
        trafficDensityCount,
        emergencySpeedKmh,
        corridorResult,
        simulatedVehicles,
        connectionStatus,
        setTrafficDensity,
        setEmergencySpeed,
        runEmergencySimulation,
        stopSimulation,
      }}
    >
      {children}
    </SimulationContext.Provider>
  );
};

export const useSimulation = () => {
  const context = useContext(SimulationContext);
  if (!context) throw new Error('useSimulation must be used within a SimulationProvider');
  return context;
};
