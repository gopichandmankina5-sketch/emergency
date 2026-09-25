import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/vehicle.dart';
import '../models/corridor.dart';
import '../models/alert.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = 'http://10.0.2.2:8000/api';

  void setBaseUrl(String url) {
    String clean = url.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    _baseUrl = clean.endsWith('/api') ? clean : '${clean.replaceAll(RegExp(r'/$'), '')}/api';
  }

  String get baseUrl => _baseUrl;

  Future<bool> registerVehicle({
    required String vehicleId,
    bool isEmergency = false,
    String? emergencyType,
    String? fcmToken,
    double latitude = 13.0827,
    double longitude = 80.2707,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/vehicles/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'vehicleId': vehicleId,
              'isEmergency': isEmergency,
              'emergencyType': emergencyType,
              'fcmToken': fcmToken ?? 'mock_token_$vehicleId',
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] registerVehicle error: $e');
      return false;
    }
  }

  Future<bool> registerFcmToken(String vehicleId, String fcmToken) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/vehicles/fcm-token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'vehicleId': vehicleId,
              'fcmToken': fcmToken,
            }),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] registerFcmToken error: $e');
      return false;
    }
  }

  Future<bool> updateVehicleLocation({
    required String vehicleId,
    required double latitude,
    required double longitude,
    double speed = 0.0,
    double heading = 0.0,
    bool locationEnabled = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/vehicles/location'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'vehicleId': vehicleId,
              'latitude': latitude,
              'longitude': longitude,
              'speed': speed,
              'heading': heading,
              'locationEnabled': locationEnabled,
              'lastUpdated': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] updateVehicleLocation error: $e');
      return false;
    }
  }

  Future<CorridorResult?> startEmergency({
    required String vehicleId,
    required String type,
    required double latitude,
    required double longitude,
    double speed = 45.0,
    double heading = 90.0,
    required double destLat,
    required double destLon,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/emergency/start'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'vehicleId': vehicleId,
              'type': type,
              'latitude': latitude,
              'longitude': longitude,
              'speed': speed,
              'heading': heading,
              'destination': {'latitude': destLat, 'longitude': destLon},
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['corridor'] != null) {
          return CorridorResult.fromJson(data['corridor']);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] startEmergency error: $e');
    }
    return null;
  }

  Future<CorridorResult?> updateEmergencyLocation({
    required String vehicleId,
    required double latitude,
    required double longitude,
    double speed = 45.0,
    double heading = 90.0,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/emergency/location'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'vehicleId': vehicleId,
              'latitude': latitude,
              'longitude': longitude,
              'speed': speed,
              'heading': heading,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['corridor'] != null) {
          return CorridorResult.fromJson(data['corridor']);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] updateEmergencyLocation error: $e');
    }
    return null;
  }

  Future<bool> stopEmergency([String vehicleId = 'AMB001']) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/emergency/stop?vehicleId=$vehicleId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] stopEmergency error: $e');
      return false;
    }
  }

  Future<CorridorResult?> fetchCorridor([String emergencyId = 'AMB001']) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/emergency/$emergencyId/corridor'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && (data['active'] == true || data['corridorPolygon'] != null)) {
          return CorridorResult.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] fetchCorridor error: $e');
    }
    return null;
  }

  Future<List<Vehicle>> fetchNearbyVehicles({double radius = 800}) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/vehicles/nearby?radius=$radius'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['vehicles'] is List) {
          return (data['vehicles'] as List)
              .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] fetchNearbyVehicles error: $e');
    }
    return [];
  }

  Future<CorridorAlert?> fetchAlertForVehicle(String vehicleId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/alerts/$vehicleId'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['hasAlert'] == true && data['latestAlert'] != null) {
          return CorridorAlert.fromJson(data['latestAlert']);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] fetchAlertForVehicle error: $e');
    }
    return null;
  }

  Future<AnalyticsSummary?> fetchAnalyticsSummary() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/analytics'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return AnalyticsSummary.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('[ApiService] fetchAnalyticsSummary error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchSuccessCriteria() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/success-criteria'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] fetchSuccessCriteria error: $e');
    }
    return null;
  }
}
