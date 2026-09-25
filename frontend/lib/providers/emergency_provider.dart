import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/corridor.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';

class EmergencyProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isEmergencyActive = false;
  String _emergencyVehicleId = "AMB001";
  String _emergencyType = "AMBULANCE";
  double _lat = 13.0800;
  double _lon = 80.2680;
  double _speed = 45.0;
  double _heading = 90.0;
  double _destLat = 13.1000;
  double _destLon = 80.3000;

  CorridorResult? _activeCorridor;
  List<Vehicle> _nearbyVehicles = [];
  Timer? _telemetryTimer;

  bool get isEmergencyActive => _isEmergencyActive;
  String get vehicleId => _emergencyVehicleId;
  String get emergencyType => _emergencyType;
  double get latitude => _lat;
  double get longitude => _lon;
  double get speed => _speed;
  double get heading => _heading;
  CorridorResult? get activeCorridor => _activeCorridor;
  List<Vehicle> get nearbyVehicles => _nearbyVehicles;

  void setEmergencyType(String type) {
    _emergencyType = type;
    notifyListeners();
  }

  Future<void> startEmergencyMission() async {
    _isEmergencyActive = true;
    notifyListeners();

    final result = await _apiService.startEmergency(
      vehicleId: _emergencyVehicleId,
      type: _emergencyType,
      latitude: _lat,
      longitude: _lon,
      speed: _speed,
      heading: _heading,
      destLat: _destLat,
      destLon: _destLon,
    );

    if (result != null) {
      _activeCorridor = result;
    }

    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isEmergencyActive) {
        timer.cancel();
        return;
      }
      // Stream incremental simulated movement forward
      _lat += 0.0003;
      _lon += 0.0003;
      final corridor = await _apiService.fetchCorridor(_emergencyVehicleId);
      if (corridor != null) {
        _activeCorridor = corridor;
      }
      _nearbyVehicles = await _apiService.fetchNearbyVehicles();
      notifyListeners();
    });
  }

  void stopEmergencyMission() {
    _isEmergencyActive = false;
    _telemetryTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }
}
