import 'vehicle.dart';
import 'alert.dart';

class CorridorResult {
  final String emergencyVehicleId;
  final bool active;
  final List<LatLngData> predictedRoute;
  final List<LatLngData> corridorPolygon;
  final int totalNearbyVehicles;
  final int obstructingVehiclesCount;
  final int instructedToMoveCount;
  final List<CorridorAlert> alerts;
  final double corridorScore;
  final String timestamp;

  CorridorResult({
    required this.emergencyVehicleId,
    required this.active,
    required this.predictedRoute,
    required this.corridorPolygon,
    required this.totalNearbyVehicles,
    required this.obstructingVehiclesCount,
    required this.instructedToMoveCount,
    required this.alerts,
    required this.corridorScore,
    required this.timestamp,
  });

  factory CorridorResult.fromJson(Map<String, dynamic> json) {
    var routeList = (json['predictedRoute'] as List<dynamic>?)
            ?.map((e) => LatLngData.fromJson(e))
            .toList() ??
        [];
    var polyList = (json['corridorPolygon'] as List<dynamic>?)
            ?.map((e) => LatLngData.fromJson(e))
            .toList() ??
        [];
    var alertList = (json['alerts'] as List<dynamic>?)
            ?.map((e) => CorridorAlert.fromJson(e))
            .toList() ??
        [];

    return CorridorResult(
      emergencyVehicleId: json['emergencyVehicleId'] ?? 'AMB001',
      active: json['active'] ?? false,
      predictedRoute: routeList,
      corridorPolygon: polyList,
      totalNearbyVehicles: json['totalNearbyVehicles'] ?? 0,
      obstructingVehiclesCount: json['obstructingVehiclesCount'] ?? 0,
      instructedToMoveCount: json['instructedToMoveCount'] ?? 0,
      alerts: alertList,
      corridorScore: (json['corridorScore'] as num?)?.toDouble() ?? 100.0,
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}
