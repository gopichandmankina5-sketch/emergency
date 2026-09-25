import 'dart:async';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/corridor.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

enum ConnectionStateEnum { live, connecting, offline, gpsStale }

class EmergencyProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  bool _isEmergencyActive = false;
  String _emergencyVehicleId = 'AMB001';
  String _emergencyType = 'AMBULANCE';
  double _latitude = 13.0800;
  double _longitude = 80.2680;
  double _speed = 45.0;
  double _heading = 90.0;
  double _destLat = 13.1000;
  double _destLon = 80.3000;

  CorridorResult? _activeCorridor;
  List<Vehicle> _nearbyVehicles = [];
  bool _isLiveGpsMode = true;

  ConnectionStateEnum _connectionState = ConnectionStateEnum.offline;
  int _consecutiveFailures = 0;
  Timer? _telemetryTimer;

  // Getters
  bool get isEmergencyActive => _isEmergencyActive;
  String get emergencyVehicleId => _emergencyVehicleId;
  String get emergencyType => _emergencyType;
  double get latitude => _latitude;
  double get longitude => _longitude;
  double get speed => _speed;
  double get heading => _heading;
  double get destLat => _destLat;
  double get destLon => _destLon;
  CorridorResult? get activeCorridor => _activeCorridor;
  List<Vehicle> get nearbyVehicles => _nearbyVehicles;
  bool get isLiveGpsMode => _isLiveGpsMode;
  ConnectionStateEnum get connectionState => _connectionState;

  String get connectionStatusText {
    switch (_connectionState) {
      case ConnectionStateEnum.live:
        return '🟢 LIVE';
      case ConnectionStateEnum.connecting:
        return '🟡 CONNECTING';
      case ConnectionStateEnum.gpsStale:
        return '⚠️ GPS STALE';
      case ConnectionStateEnum.offline:
        return '🔴 OFFLINE';
    }
  }

  Color get connectionBadgeColor {
    switch (_connectionState) {
      case ConnectionStateEnum.live:
        return const Color(0xFF10B981);
      case ConnectionStateEnum.connecting:
        return const Color(0xFFEAB308);
      case ConnectionStateEnum.gpsStale:
        return const Color(0xFFF59E0B);
      case ConnectionStateEnum.offline:
        return const Color(0xFFEF4444);
    }
  }

  void setEmergencyVehicleId(String id) {
    if (id.isNotEmpty) {
      _emergencyVehicleId = id.trim().toUpperCase();
      notifyListeners();
    }
  }

  void setEmergencyType(String type) {
    _emergencyType = type;
    notifyListeners();
  }

  void setDestination(double lat, double lon) {
    _destLat = lat;
    _destLon = lon;
    notifyListeners();
  }

  void toggleLiveGpsMode(bool enabled) {
    _isLiveGpsMode = enabled;
    notifyListeners();
  }

  Future<void> startEmergencyMission() async {
    _isEmergencyActive = true;
    notifyListeners();

    double curLat = _latitude;
    double curLon = _longitude;
    double curSpeed = _speed;
    double curHeading = _heading;

    if (_isLiveGpsMode) {
      final loc = await _locationService.getCurrentLocation();
      if (loc != null) {
        curLat = loc.latitude;
        curLon = loc.longitude;
        curSpeed = loc.speed;
        curHeading = loc.heading;
        _latitude = curLat;
        _longitude = curLon;
        _speed = curSpeed;
        _heading = curHeading;
      }
    }

    final corridor = await _apiService.startEmergency(
      vehicleId: _emergencyVehicleId,
      type: _emergencyType,
      latitude: curLat,
      longitude: curLon,
      speed: curSpeed,
      heading: curHeading,
      destLat: _destLat,
      destLon: _destLon,
    );

    if (corridor != null) {
      _activeCorridor = corridor;
      _recordSuccess();
    } else {
      _recordFailure();
    }

    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      double updateLat = curLat;
      double updateLon = curLon;
      double updateSpeed = curSpeed;
      double updateHeading = curHeading;

      if (_isLiveGpsMode) {
        final loc = await _locationService.getCurrentLocation();
        if (loc != null) {
          updateLat = loc.latitude;
          updateLon = loc.longitude;
          updateSpeed = loc.speed;
          updateHeading = loc.heading;
          _latitude = updateLat;
          _longitude = updateLon;
          _speed = updateSpeed;
          _heading = updateHeading;
        }
      } else {
        updateLat += 0.0003;
        updateLon += 0.0003;
        _latitude = updateLat;
        _longitude = updateLon;
      }

      curLat = updateLat;
      curLon = updateLon;

      final updatedCorridor = await _apiService.updateEmergencyLocation(
        vehicleId: _emergencyVehicleId,
        latitude: updateLat,
        longitude: updateLon,
        speed: updateSpeed,
        heading: updateHeading,
      );

      if (updatedCorridor != null) {
        _activeCorridor = updatedCorridor;
        _recordSuccess();
      } else {
        _recordFailure();
      }

      final nearby = await _apiService.fetchNearbyVehicles();
      _nearbyVehicles = nearby;
      notifyListeners();
    });
  }

  Future<void> stopEmergencyMission() async {
    _isEmergencyActive = false;
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    await _apiService.stopEmergency(_emergencyVehicleId);
    notifyListeners();
  }

  void _recordSuccess() {
    _consecutiveFailures = 0;
    _connectionState = ConnectionStateEnum.live;
    notifyListeners();
  }

  void _recordFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= 3) {
      _connectionState = ConnectionStateEnum.offline;
    } else {
      _connectionState = ConnectionStateEnum.connecting;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }
}
