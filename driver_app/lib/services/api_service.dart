import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/vehicle.dart';
import '../models/corridor.dart';
import '../models/alert.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService({http.Client? client}) {
    if (client != null) _instance.client = client;
    return _instance;
  }
  ApiService._internal();

  http.Client client = http.Client();

  void setClient(http.Client customClient) {
    client = customClient;
  }

  String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.137.1:8000/api',
  );

  void setBaseUrl(String url) {
    String clean = url.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    _baseUrl = clean.endsWith('/api') ? clean : '${clean.replaceAll(RegExp(r'/$'), '')}/api';
    debugPrint('[ApiService] Base URL updated to: $_baseUrl');
  }

  String get baseUrl => _baseUrl;

  Future<bool> registerDriverVehicle({
    required String vehicleId,
    String? fcmToken,
    double latitude = 13.0827,
    double longitude = 80.2707,
  }) async {
    final url = '$_baseUrl/vehicles/register';
    debugPrint('[ApiService] POST $url (vehicleId: $vehicleId)');
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'vehicleId': vehicleId,
              'isEmergency': false,
              'fcmToken': fcmToken ?? 'mock_token_$vehicleId',
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 10));
      debugPrint('[ApiService] POST $url -> STATUS ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] registerDriverVehicle ERROR: $e');
      return false;
    }
  }

  Future<bool> registerFcmToken(String vehicleId, String fcmToken) async {
    final url = '$_baseUrl/vehicles/fcm-token';
    debugPrint('[ApiService] POST $url (vehicleId: $vehicleId)');
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'vehicleId': vehicleId,
              'fcmToken': fcmToken,
            }),
          )
          .timeout(const Duration(seconds: 10));
      debugPrint('[ApiService] POST $url -> STATUS ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] registerFcmToken ERROR: $e');
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
    final url = '$_baseUrl/vehicles/location';
    try {
      final response = await client
          .post(
            Uri.parse(url),
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
          .timeout(const Duration(seconds: 10));
      debugPrint('[ApiService] POST $url -> STATUS ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] updateVehicleLocation ERROR: $e');
      return false;
    }
  }

  Future<CorridorAlert?> fetchAlertForVehicle(String vehicleId) async {
    final url = '$_baseUrl/alerts/$vehicleId';
    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      debugPrint('[ApiService] GET $url -> STATUS ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['hasAlert'] == true) {
          if (data['alerts'] is List && (data['alerts'] as List).isNotEmpty) {
            final latestAlertJson = (data['alerts'] as List).last;
            if (latestAlertJson is Map<String, dynamic> && latestAlertJson['active'] != false) {
              return CorridorAlert.fromJson(latestAlertJson);
            }
          } else if (data['latestAlert'] != null && data['latestAlert'] is Map<String, dynamic>) {
            final latestAlertJson = data['latestAlert'];
            if (latestAlertJson['active'] != false) {
              return CorridorAlert.fromJson(latestAlertJson);
            }
          }
        }
        // When hasAlert == false or no active alerts in array, return null (never use historical allAlerts)
        return null;
      }
    } catch (e) {
      debugPrint('[ApiService] fetchAlertForVehicle ERROR: $e');
    }
    return null;
  }

  Future<bool> acknowledgeAlert(String vehicleId) async {
    final url = '$_baseUrl/alerts/$vehicleId/acknowledge';
    debugPrint('[ApiService] POST $url (vehicleId: $vehicleId)');
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      debugPrint('[ApiService] POST $url -> STATUS ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] acknowledgeAlert ERROR: $e');
      return false;
    }
  }

  Future<CorridorResult?> fetchCorridor([String emergencyId = 'AMB001']) async {
    final url = '$_baseUrl/emergency/$emergencyId/corridor';
    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      debugPrint('[ApiService] GET $url -> STATUS ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && (data['active'] == true || data['corridorPolygon'] != null)) {
          return CorridorResult.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] fetchCorridor ERROR: $e');
    }
    return null;
  }

  Future<List<Vehicle>> fetchNearbyVehicles({double radius = 800}) async {
    final url = '$_baseUrl/vehicles/nearby?radius=$radius';
    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      debugPrint('[ApiService] GET $url -> STATUS ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['vehicles'] is List) {
          return (data['vehicles'] as List)
              .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] fetchNearbyVehicles ERROR: $e');
    }
    return [];
  }
}

