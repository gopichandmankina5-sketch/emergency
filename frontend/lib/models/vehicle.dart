class LatLngData {
  final double latitude;
  final double longitude;

  LatLngData({required this.latitude, required this.longitude});

  factory LatLngData.fromJson(Map<String, dynamic> json) {
    return LatLngData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

class Vehicle {
  final String vehicleId;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final bool locationEnabled;
  final bool isEmergency;
  final String? emergencyType;

  Vehicle({
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    this.speed = 0.0,
    this.heading = 0.0,
    this.locationEnabled = true,
    this.isEmergency = false,
    this.emergencyType,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicleId'] ?? 'UNKNOWN',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      locationEnabled: json['locationEnabled'] ?? true,
      isEmergency: json['isEmergency'] ?? false,
      emergencyType: json['emergencyType'],
    );
  }

  Map<String, dynamic> toJson() => {
        'vehicleId': vehicleId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'heading': heading,
        'locationEnabled': locationEnabled,
        'isEmergency': isEmergency,
        'emergencyType': emergencyType,
      };
}

class EmergencyVehicle extends Vehicle {
  final bool emergencyActive;
  final LatLngData destination;

  EmergencyVehicle({
    required String vehicleId,
    required double latitude,
    required double longitude,
    required double speed,
    required double heading,
    required String emergencyType,
    required this.emergencyActive,
    required this.destination,
  }) : super(
          vehicleId: vehicleId,
          latitude: latitude,
          longitude: longitude,
          speed: speed,
          heading: heading,
          isEmergency: true,
          emergencyType: emergencyType,
        );

  factory EmergencyVehicle.fromJson(Map<String, dynamic> json) {
    return EmergencyVehicle(
      vehicleId: json['vehicleId'] ?? 'AMB001',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      emergencyType: json['type'] ?? 'AMBULANCE',
      emergencyActive: json['emergencyActive'] ?? true,
      destination: LatLngData.fromJson(json['destination'] ?? {'latitude': 13.1000, 'longitude': 80.3000}),
    );
  }
}
