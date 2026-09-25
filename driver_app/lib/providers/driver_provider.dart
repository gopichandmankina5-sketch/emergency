import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final List<CorridorAlert> _alertHistory = [];
  CorridorResult? _activeCorridor;
  List<Vehicle> _nearbyVehicles = [];

  bool _isLiveGpsMode = true;
  Timer? _heartbeatTimer;
  bool _isHeartbeatProcessing = false;
  String? _lastSentTokenKey;

  DriverProvider() {
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('driver_vehicle_id');
      final savedReg = prefs.getBool('driver_registered') ?? false;

      if (savedId != null && savedId.isNotEmpty) {
        _vehicleId = savedId;
      }
      if (savedReg) {
        _isRegistered = true;
        debugPrint('[DriverProvider] Restored registered vehicle $_vehicleId from SharedPreferences');
        _startHeartbeatLoop();
      }

      _fcmService.setOnTokenChangedCallback((token) {
        syncFcmTokenToBackend(token);
      });

      final currentToken = await _fcmService.getSavedToken();
      if (currentToken != null && currentToken.isNotEmpty) {
        await syncFcmTokenToBackend(currentToken);
      }
    } catch (e) {
      debugPrint('[DriverProvider] Error loading saved state: $e');
    }
    notifyListeners();
  }

  Future<void> _saveStateLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('driver_vehicle_id', _vehicleId);
      await prefs.setBool('driver_registered', _isRegistered);
      debugPrint('[DriverProvider] Saved state locally: vehicleId=$_vehicleId, isRegistered=$_isRegistered');
    } catch (e) {
      debugPrint('[DriverProvider] Error saving state locally: $e');
    }
  }

  Future<bool> syncFcmTokenToBackend(String token) async {
    if (!_isRegistered || _vehicleId.isEmpty || token.isEmpty) {
      debugPrint('[DriverProvider] syncFcmTokenToBackend skipped: isRegistered=$_isRegistered, vehicleId=$_vehicleId, tokenPresent=${token.isNotEmpty}');
      return false;
    }

    final key = '${_vehicleId}_$token';
    if (_lastSentTokenKey == key) {
      debugPrint('[DriverProvider] FCM token already synced to backend for key: $key');
      return true;
    }

    debugPrint('[DriverProvider] Sending FCM token to backend for $_vehicleId...');
    final success = await _apiService.registerFcmToken(_vehicleId, token);
    if (success) {
      _lastSentTokenKey = key;
      debugPrint('[FCM] Token synced for $_vehicleId');
      debugPrint('[DriverProvider] FCM token synced to backend successfully for $_vehicleId');
    } else {
      debugPrint('[DriverProvider] Failed to sync FCM token to backend for $_vehicleId (retaining token for retry)');
    }
    return success;
  }

  // Getters
  String get vehicleId => _vehicleId;
  bool get isRegistered => _isRegistered;
  double get latitude => _latitude;
  double get longitude => _longitude;
  double get speed => _speed;
  double get heading => _heading;
  bool get locationSharingEnabled => _locationSharingEnabled;
  CorridorAlert? get activeAlert => _activeAlert;
  List<CorridorAlert> get alertHistory => _alertHistory;
  CorridorResult? get activeCorridor => _activeCorridor;
  List<Vehicle> get nearbyVehicles => _nearbyVehicles;
  bool get isLiveGpsMode => _isLiveGpsMode;

  void setVehicleId(String id) {
    final cleanId = id.trim().toUpperCase();
    if (cleanId.isNotEmpty && cleanId != _vehicleId) {
      _vehicleId = cleanId;
      _lastSentTokenKey = null;
      _saveStateLocally();
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

    if (_isLiveGpsMode && _locationSharingEnabled) {
      try {
        final loc = await _locationService.getCurrentLocation();
        if (loc != null) {
          _latitude = loc.latitude;
          _longitude = loc.longitude;
          _speed = loc.speed;
          _heading = loc.heading;
        }
      } catch (e) {
        debugPrint('[DriverProvider] Initial location fetch error: $e');
      }
    }

    final token = _fcmService.fcmToken ?? await _fcmService.getSavedToken() ?? 'mock_token_$_vehicleId';

    bool success = await _apiService.registerDriverVehicle(
      vehicleId: _vehicleId,
      fcmToken: token,
      latitude: _latitude,
      longitude: _longitude,
    );

    if (!success) {
      debugPrint('[DriverProvider] registerDriverVehicle returned false, trying location update fallback...');
      success = await _apiService.updateVehicleLocation(
        vehicleId: _vehicleId,
        latitude: _latitude,
        longitude: _longitude,
        speed: _speed,
        heading: _heading,
        locationEnabled: _locationSharingEnabled,
      );
    }

    if (success) {
      _isRegistered = true;
      debugPrint('[DriverProvider] REGISTER SUCCESS $_vehicleId');
      _saveStateLocally();
      await syncFcmTokenToBackend(token);
    } else {
      if (!_isRegistered) {
        debugPrint('[DriverProvider] Initial registration attempt failed for $_vehicleId');
      } else {
        debugPrint('[DriverProvider] Registration endpoint error, KEEPING REGISTERED STATE for $_vehicleId');
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
    _lastSentTokenKey = null;
    _saveStateLocally();
    debugPrint('[DriverProvider] DISCONNECTED $_vehicleId');
    notifyListeners();
  }

  void handleAppResumed() {
    debugPrint('[DriverProvider] App resumed, ensuring heartbeat is active for $_vehicleId...');
    if (_isRegistered && (_heartbeatTimer == null || !_heartbeatTimer!.isActive)) {
      _startHeartbeatLoop();
    } else if (_isRegistered) {
      _runHeartbeatTick();
    }
  }

  Future<void> acknowledgeAlert() async {
    if (_activeAlert != null) {
      await _apiService.acknowledgeAlert(_vehicleId);
      await _fcmService.cancelAllNotifications();
      _fcmService.resetNotificationState();
      _activeAlert = null;
      notifyListeners();
    }
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
          debugPrint('[DriverProvider] Heartbeat GPS location error: $e');
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
          _saveStateLocally();
        }
        debugPrint('[DriverProvider] HEARTBEAT SUCCESS $_vehicleId');
      } else {
        debugPrint('[DriverProvider] HEARTBEAT FAILED $_vehicleId');
        if (_isRegistered) {
          debugPrint('[DriverProvider] KEEPING REGISTERED STATE');
        }
      }

      if (_isRegistered && _lastSentTokenKey == null) {
        final currentToken = _fcmService.fcmToken ?? await _fcmService.getSavedToken();
        if (currentToken != null && currentToken.isNotEmpty) {
          await syncFcmTokenToBackend(currentToken);
        }
      }

      try {
        final alert = await _apiService.fetchAlertForVehicle(_vehicleId);
        if (alert != null && alert.action.isNotEmpty && alert.action != 'NO_ALERT') {
          if (_fcmService.shouldNotify(alert.emergencyVehicleId, alert.vehicleId, alert.action)) {
            _fcmService.triggerHapticAlert(alert.action);
            await _fcmService.showLocalNotification(
              title: '🚨 EMERGENCY VEHICLE APPROACHING',
              body: alert.actionText,
            );
            if (!_alertHistory.any((h) => h.timestamp == alert.timestamp && h.action == alert.action)) {
              _alertHistory.insert(0, alert);
            }
          }
          _activeAlert = alert;
        } else {
          // Emergency is stopped, hasAlert is false, or NO_ALERT -> clear active alert state & cancel active notifications
          final hadActiveAlert = _activeAlert != null;
          _activeAlert = null;
          if (hadActiveAlert) {
            _fcmService.resetNotificationState();
            await _fcmService.cancelAllNotifications();
          }
        }
      } catch (e) {
        debugPrint('[DriverProvider] fetchAlert error: $e');
      }

      try {
        final corridor = await _apiService.fetchCorridor('AMB001');
        _activeCorridor = corridor;
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

