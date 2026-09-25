class Vehicle {
  final String vehicleId;
  final bool isEmergency;
  final String? emergencyType;
  final String? fcmToken;
  final bool locationEnabled;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final String? lastUpdated;

  Vehicle({
    required this.vehicleId,
    this.isEmergency = false,
    this.emergencyType,
    this.fcmToken,
    this.locationEnabled = true,
    required this.latitude,
    required this.longitude,
    this.speed = 0.0,
    this.heading = 0.0,
    this.lastUpdated,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicleId']?.toString() ?? 'UNKNOWN',
      isEmergency: json['isEmergency'] == true,
      emergencyType: json['emergencyType']?.toString(),
      fcmToken: json['fcmToken']?.toString(),
      locationEnabled: json['locationEnabled'] ?? true,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 13.0827,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 80.2707,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['lastUpdated']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'isEmergency': isEmergency,
      'emergencyType': emergencyType,
      'fcmToken': fcmToken,
      'locationEnabled': locationEnabled,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'lastUpdated': lastUpdated,
    };
  }
}
