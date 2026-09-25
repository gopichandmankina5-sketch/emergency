import 'package:latlong2/latlong.dart';

class CorridorPoint {
  final double latitude;
  final double longitude;

  CorridorPoint({required this.latitude, required this.longitude});

  factory CorridorPoint.fromJson(Map<String, dynamic> json) {
    return CorridorPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  LatLng toLatLng() => LatLng(latitude, longitude);
}

class CorridorResult {
  final bool active;
  final String emergencyVehicleId;
  final String emergencyType;
  final List<CorridorPoint> predictedRoute;
  final List<CorridorPoint> corridorPolygon;
  final int totalNearbyVehicles;
  final int obstructingVehiclesCount;
  final int instructedToMoveCount;
  final double corridorScore;
  final String timestamp;

  CorridorResult({
    required this.active,
    required this.emergencyVehicleId,
    required this.emergencyType,
    required this.predictedRoute,
    required this.corridorPolygon,
    required this.totalNearbyVehicles,
    required this.obstructingVehiclesCount,
    required this.instructedToMoveCount,
    required this.corridorScore,
    required this.timestamp,
  });

  factory CorridorResult.fromJson(Map<String, dynamic> json) {
    var routeList = (json['predictedRoute'] as List<dynamic>?)
            ?.map((e) => CorridorPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    var polyList = (json['corridorPolygon'] as List<dynamic>?)
            ?.map((e) => CorridorPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return CorridorResult(
      active: json['active'] ?? true,
      emergencyVehicleId: json['emergencyVehicleId']?.toString() ?? 'AMB001',
      emergencyType: json['emergencyType']?.toString() ?? 'AMBULANCE',
      predictedRoute: routeList,
      corridorPolygon: polyList,
      totalNearbyVehicles: (json['totalNearbyVehicles'] as num?)?.toInt() ?? 0,
      obstructingVehiclesCount: (json['obstructingVehiclesCount'] as num?)?.toInt() ?? 0,
      instructedToMoveCount: (json['instructedToMoveCount'] as num?)?.toInt() ?? 0,
      corridorScore: (json['corridorScore'] as num?)?.toDouble() ?? 100.0,
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}
