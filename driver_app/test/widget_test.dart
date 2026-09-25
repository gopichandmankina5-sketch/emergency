import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/models/vehicle.dart';
import 'package:driver_app/models/alert.dart';

void main() {
  test('Driver Vehicle model serialization test', () {
    final vehicle = Vehicle(
      vehicleId: 'V102',
      isEmergency: false,
      latitude: 13.0827,
      longitude: 80.2707,
    );

    expect(vehicle.vehicleId, 'V102');
    expect(vehicle.isEmergency, isFalse);

    final json = vehicle.toJson();
    expect(json['vehicleId'], 'V102');

    final parsed = Vehicle.fromJson(json);
    expect(parsed.vehicleId, 'V102');
  });

  test('CorridorAlert parsing test', () {
    final rawJson = {
      'vehicleId': 'V102',
      'emergencyVehicleId': 'AMB001',
      'distance': 180.0,
      'speed': 32.0,
      'heading': 90.0,
      'obstructionScore': 85.0,
      'eta': 14.0,
      'action': 'MOVE_RIGHT',
      'actionText': 'MOVE RIGHT WHEN SAFE',
      'message': 'AMB001 is approaching. Clear corridor.',
      'alertColor': '#dc2626',
      'isUrgent': true,
      'timestamp': '2026-09-23T10:00:00Z',
    };

    final alert = CorridorAlert.fromJson(rawJson);
    expect(alert.vehicleId, 'V102');
    expect(alert.action, 'MOVE_RIGHT');
    expect(alert.actionText, 'MOVE RIGHT WHEN SAFE');
    expect(alert.isUrgent, isTrue);
  });
}
