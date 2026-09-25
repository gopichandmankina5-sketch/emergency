import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_vehicle_app/models/vehicle.dart';
import 'package:emergency_vehicle_app/models/corridor.dart';

void main() {
  test('Emergency Vehicle model serialization test', () {
    final vehicle = Vehicle(
      vehicleId: 'AMB001',
      isEmergency: true,
      emergencyType: 'AMBULANCE',
      latitude: 13.0800,
      longitude: 80.2680,
    );

    expect(vehicle.vehicleId, 'AMB001');
    expect(vehicle.isEmergency, isTrue);

    final json = vehicle.toJson();
    expect(json['vehicleId'], 'AMB001');

    final parsed = Vehicle.fromJson(json);
    expect(parsed.vehicleId, 'AMB001');
  });

  test('CorridorResult parsing test', () {
    final rawJson = {
      'active': true,
      'emergencyVehicleId': 'AMB001',
      'emergencyType': 'AMBULANCE',
      'predictedRoute': [
        {'latitude': 13.0800, 'longitude': 80.2680}
      ],
      'corridorPolygon': [
        {'latitude': 13.0800, 'longitude': 80.2675},
        {'latitude': 13.0850, 'longitude': 80.2695},
        {'latitude': 13.0850, 'longitude': 80.2705},
      ],
      'totalNearbyVehicles': 3,
      'obstructingVehiclesCount': 1,
      'instructedToMoveCount': 1,
      'corridorScore': 95.0,
      'timestamp': '2026-09-23T10:00:00Z',
    };

    final result = CorridorResult.fromJson(rawJson);
    expect(result.active, isTrue);
    expect(result.emergencyVehicleId, 'AMB001');
    expect(result.corridorPolygon.length, 3);
  });
}
