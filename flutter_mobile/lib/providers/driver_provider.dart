import 'dart:async';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/alert.dart';
import '../models/corridor.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/fcm_service.dart';

class DriverProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final FcmService _fcmService = FcmService();

  String _vehicleId = 'V102';
  bool _isRegistered = false;
  double _latitude = 13.0827;
  double _longitude = 80.2707;
  double _speed = 35.0;
  double _heading = 90.0;
  bool _locationSharingEnabled = true;

  CorridorAlert? _activeAlert;
  CorridorResult? _activeCorridor;
  List<Vehicle> _nearbyVehicles = [];

  bool _isLiveGpsMode = true;
  Timer? _heartbeatTimer;
  bool _isHeartbeatProcessing = false;

  // Getters
  String get vehicleId => _vehicleId;
  bool get isRegistered => _isRegistered;
  double get latitude => _latitude;
  double get longitude => _longitude;
  double get speed => _speed;
  double get heading => _heading;
  bool get locationSharingEnabled => _locationSharingEnabled;
  CorridorAlert? get activeAlert => _activeAlert;
  CorridorResult? get activeCorridor => _activeCorridor;
  List<Vehicle> get nearbyVehicles => _nearbyVehicles;
  bool get isLiveGpsMode => _isLiveGpsMode;

  void setVehicleId(String id) {
    final cleanId = id.trim().toUpperCase();
    if (cleanId.isNotEmpty && cleanId != _vehicleId) {
      _vehicleId = cleanId;
      notifyListeners();
    }
  }

  void toggleLocationSharing(bool enabled) {
    _locationSharingEnabled = enabled;
    notifyListeners();
  }

  void toggleLiveGpsMode(bool enabled) {
    _isLiveGpsMode = enabled;
    notifyListeners();
  }

  Future<void> registerVehicle() async {
    debugPrint('[DriverProvider] CONNECT $_vehicleId');
    final token = _fcmService.fcmToken ?? 'mock_token_$_vehicleId';

    bool success = await _apiService.registerVehicle(
      vehicleId: _vehicleId,
      isEmergency: false,
      fcmToken: token,
      latitude: _latitude,
      longitude: _longitude,
    );

    if (success) {
      _isRegistered = true;
      debugPrint('[DriverProvider] REGISTER SUCCESS $_vehicleId');
    } else {
      if (!_isRegistered) {
        debugPrint('[DriverProvider] Initial registration attempt failed for $_vehicleId');
      } else {
        debugPrint('[DriverProvider] Registration error, KEEPING REGISTERED STATE for $_vehicleId');
      }
    }
    notifyListeners();

    _startHeartbeatLoop();
  }

  void disconnectVehicle() {
    _isRegistered = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _activeAlert = null;
    _activeCorridor = null;
    _nearbyVehicles.clear();
    debugPrint('[DriverProvider] DISCONNECTED $_vehicleId');
    notifyListeners();
  }

  void _startHeartbeatLoop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _runHeartbeatTick();
    });
  }

  Future<void> _runHeartbeatTick() async {
    if (_isHeartbeatProcessing) return;
    _isHeartbeatProcessing = true;

    try {
      double curLat = _latitude;
      double curLon = _longitude;
      double curSpeed = _speed;
      double curHeading = _heading;

      if (_isLiveGpsMode && _locationSharingEnabled) {
        try {
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
        } catch (e) {
          debugPrint('[DriverProvider] Location error: $e');
        }
      }

      bool locationSuccess = false;
      try {
        locationSuccess = await _apiService.updateVehicleLocation(
          vehicleId: _vehicleId,
          latitude: curLat,
          longitude: curLon,
          speed: curSpeed,
          heading: curHeading,
          locationEnabled: _locationSharingEnabled,
        );
      } catch (e) {
        debugPrint('[DriverProvider] updateVehicleLocation exception: $e');
      }

      if (locationSuccess) {
        if (!_isRegistered) {
          _isRegistered = true;
          debugPrint('[DriverProvider] REGISTER SUCCESS $_vehicleId');
        }
        debugPrint('[DriverProvider] HEARTBEAT SUCCESS $_vehicleId');
      } else {
        debugPrint('[DriverProvider] HEARTBEAT FAILED $_vehicleId');
        if (_isRegistered) {
          debugPrint('[DriverProvider] KEEPING REGISTERED STATE');
        }
      }

      try {
        final alert = await _apiService.fetchAlertForVehicle(_vehicleId);
        if (alert != null) {
          if (_activeAlert?.action != alert.action) {
            _fcmService.triggerHapticAlert(alert.action);
          }
          _activeAlert = alert;
        }
      } catch (e) {
        debugPrint('[DriverProvider] fetchAlert error: $e');
      }

      try {
        final corridor = await _apiService.fetchCorridor('AMB001');
        if (corridor != null) {
          _activeCorridor = corridor;
        }
      } catch (e) {
        debugPrint('[DriverProvider] fetchCorridor error: $e');
      }

      try {
        final nearby = await _apiService.fetchNearbyVehicles();
        if (nearby.isNotEmpty) {
          _nearbyVehicles = nearby;
        }
      } catch (e) {
        debugPrint('[DriverProvider] fetchNearbyVehicles error: $e');
      }

      notifyListeners();
    } finally {
      _isHeartbeatProcessing = false;
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
