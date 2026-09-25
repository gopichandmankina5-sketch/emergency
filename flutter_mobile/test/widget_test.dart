import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mobile/models/vehicle.dart';
import 'package:flutter_mobile/models/corridor.dart';

void main() {
  test('Vehicle model JSON serialization test', () {
    final vehicle = Vehicle(
      vehicleId: 'AMB001',
      isEmergency: true,
      emergencyType: 'AMBULANCE',
      latitude: 13.0800,
      longitude: 80.2680,
      speed: 45.0,
      heading: 90.0,
    );

    expect(vehicle.vehicleId, 'AMB001');
    expect(vehicle.isEmergency, isTrue);

    final json = vehicle.toJson();
    expect(json['vehicleId'], 'AMB001');

    final parsed = Vehicle.fromJson(json);
    expect(parsed.vehicleId, 'AMB001');
    expect(parsed.latitude, 13.0800);
  });

  test('CorridorResult JSON parsing test', () {
    final rawJson = {
      'active': true,
      'emergencyVehicleId': 'AMB001',
      'emergencyType': 'AMBULANCE',
      'predictedRoute': [
        {'latitude': 13.0800, 'longitude': 80.2680},
        {'latitude': 13.0850, 'longitude': 80.2700},
      ],
      'corridorPolygon': [
        {'latitude': 13.0800, 'longitude': 80.2675},
        {'latitude': 13.0850, 'longitude': 80.2695},
        {'latitude': 13.0850, 'longitude': 80.2705},
        {'latitude': 13.0800, 'longitude': 80.2685},
      ],
      'totalNearbyVehicles': 4,
      'obstructingVehiclesCount': 2,
      'instructedToMoveCount': 2,
      'corridorScore': 88.5,
      'timestamp': '2026-09-23T10:00:00Z',
    };

    final result = CorridorResult.fromJson(rawJson);
    expect(result.active, isTrue);
    expect(result.emergencyVehicleId, 'AMB001');
    expect(result.predictedRoute.length, 2);
    expect(result.corridorPolygon.length, 4);
    expect(result.totalNearbyVehicles, 4);
  });
}
