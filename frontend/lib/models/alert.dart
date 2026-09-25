enum ActionType {
  MOVE_LEFT,
  MOVE_RIGHT,
  SLOW_DOWN,
  STAY,
  NO_ALERT,
}

enum AlertType {
  PERSONALIZED,
  GENERAL,
}

class CorridorAlert {
  final String vehicleId;
  final String emergencyVehicleId;
  final ActionType action;
  final String actionText;
  final double distance;
  final double eta;
  final AlertType alertType;
  final String status;
  final String timestamp;

  CorridorAlert({
    required this.vehicleId,
    required this.emergencyVehicleId,
    required this.action,
    required this.actionText,
    required this.distance,
    required this.eta,
    required this.alertType,
    this.status = 'SENT',
    required this.timestamp,
  });

  factory CorridorAlert.fromJson(Map<String, dynamic> json) {
    ActionType parseAction(String? val) {
      switch (val) {
        case 'MOVE_LEFT':
          return ActionType.MOVE_LEFT;
        case 'MOVE_RIGHT':
          return ActionType.MOVE_RIGHT;
        case 'SLOW_DOWN':
          return ActionType.SLOW_DOWN;
        case 'STAY':
          return ActionType.STAY;
        default:
          return ActionType.NO_ALERT;
      }
    }

    return CorridorAlert(
      vehicleId: json['vehicleId'] ?? '',
      emergencyVehicleId: json['emergencyVehicleId'] ?? '',
      action: parseAction(json['action']),
      actionText: json['actionText'] ?? json['action'] ?? 'KEEP CLEAR',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      eta: (json['eta'] as num?)?.toDouble() ?? 0.0,
      alertType: json['alertType'] == 'GENERAL' ? AlertType.GENERAL : AlertType.PERSONALIZED,
      status: json['status'] ?? 'SENT',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}
