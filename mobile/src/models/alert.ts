export type ActionType = 'MOVE_LEFT' | 'MOVE_RIGHT' | 'SLOW_DOWN' | 'STAY' | 'NO_ALERT' | 'LOCATION_OFF_WARNING';

export type AlertType = 'PERSONALIZED' | 'GENERAL';

export interface CorridorAlert {
  vehicleId: string;
  emergencyVehicleId: string;
  action: ActionType;
  actionText: string;
  distance: number;
  eta: number;
  alertType: AlertType;
  status: string;
  timestamp: string;
}
