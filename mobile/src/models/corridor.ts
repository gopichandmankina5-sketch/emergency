import { LatLngData } from './vehicle';
import { CorridorAlert } from './alert';

export interface CorridorResult {
  emergencyVehicleId: string;
  active: boolean;
  predictedRoute: LatLngData[];
  corridorPolygon: LatLngData[];
  totalNearbyVehicles: number;
  obstructingVehiclesCount: number;
  instructedToMoveCount: number;
  alerts: CorridorAlert[];
  corridorScore: number;
  timestamp: string;
}

export interface AnalyticsSummary {
  totalEvaluations: number;
  activeEmergencyVehicle?: string;
  totalRegisteredVehicles: number;
  lastUpdated?: string;
  dbStatus?: {
    mode: string;
    database: string;
    connected: boolean;
  };
}

export interface SuccessCriterion {
  id: number;
  name: string;
  status: 'PASS' | 'FAIL';
  notes: string;
}

export interface SuccessCriteriaResponse {
  totalCriteria: number;
  passed: number;
  failed: number;
  overallStatus: string;
  criteria: SuccessCriterion[];
}
