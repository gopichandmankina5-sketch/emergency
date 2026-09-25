class CorridorAlert {
  final String vehicleId;
  final String emergencyVehicleId;
  final double distance;
  final double speed;
  final double heading;
  final double obstructionScore;
  final double eta;
  final String action;
  final String actionText;
  final String message;
  final String alertColor;
  final bool isUrgent;
  final String timestamp;

  CorridorAlert({
    required this.vehicleId,
    required this.emergencyVehicleId,
    required this.distance,
    required this.speed,
    required this.heading,
    required this.obstructionScore,
    required this.eta,
    required this.action,
    required this.actionText,
    required this.message,
    required this.alertColor,
    required this.isUrgent,
    required this.timestamp,
  });

  factory CorridorAlert.fromJson(Map<String, dynamic> json) {
    String act = json['action']?.toString() ?? json['assignedAction']?.toString() ?? 'NO_ALERT';
    return CorridorAlert(
      vehicleId: json['vehicleId']?.toString() ?? 'V102',
      emergencyVehicleId: json['emergencyVehicleId']?.toString() ?? 'AMB001',
      distance: (json['distance'] as num?)?.toDouble() ?? (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? (json['speedKmh'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 90.0,
      obstructionScore: (json['obstructionScore'] as num?)?.toDouble() ?? 0.0,
      eta: (json['eta'] as num?)?.toDouble() ?? (json['predictedEtaSeconds'] as num?)?.toDouble() ?? 0.0,
      action: act,
      actionText: json['actionText']?.toString() ?? _defaultActionText(act),
      message: json['message']?.toString() ?? 'Corridor notice',
      alertColor: json['alertColor']?.toString() ?? '#10b981',
      isUrgent: json['isUrgent'] == true || json['selectedForAction'] == true,
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  static String _defaultActionText(String action) {
    switch (action) {
      case 'MOVE_LEFT':
        return 'MOVE LEFT WHEN SAFE';
      case 'MOVE_RIGHT':
        return 'MOVE RIGHT WHEN SAFE';
      case 'SLOW_DOWN':
        return 'SLOW DOWN AND KEEP CLEAR';
      case 'STAY':
        return 'STAY IN LANE';
      default:
        return 'NO ALERT';
    }
  }
}
