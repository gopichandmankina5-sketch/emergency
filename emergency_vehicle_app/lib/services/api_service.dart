import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/vehicle.dart';
import '../models/corridor.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  // Production Render Backend URL
  String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://emergency-nzyw.onrender.com/api',
  );

  void setBaseUrl(String url) {
    String clean = url.trim();

    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'https://$clean';
    }

    clean = clean.replaceAll(RegExp(r'/$'), '');

    _baseUrl = clean.endsWith('/api') ? clean : '$clean/api';

    debugPrint('[ApiService] Base URL updated: $_baseUrl');
  }

  String get baseUrl => _baseUrl;

  // ------------------------------------------------------------
  // REGISTER EMERGENCY VEHICLE
  // ------------------------------------------------------------

  Future<bool> registerEmergencyVehicle({
    required String vehicleId,
    required String type,
    String? fcmToken,
    double latitude = 13.0800,
    double longitude = 80.2680,
  }) async {
    final url = '$_baseUrl/vehicles/register';

    debugPrint('[ApiService] REGISTER POST $url | vehicleId=$vehicleId');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'vehicleId': vehicleId,
              'isEmergency': true,
              'emergencyType': type,
              'fcmToken': fcmToken ?? 'mock_token_$vehicleId',
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 5));

      debugPrint('[ApiService] REGISTER STATUS: ${response.statusCode}');

      debugPrint('[ApiService] REGISTER RESPONSE: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] registerEmergencyVehicle ERROR: $e');

      return false;
    }
  }

  // ------------------------------------------------------------
  // START EMERGENCY
  // ------------------------------------------------------------

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
    final url = '$_baseUrl/emergency/start';

    debugPrint('[ApiService] START EMERGENCY POST $url');

    debugPrint('[ApiService] vehicleId=$vehicleId');

    debugPrint('[ApiService] emergencyType=$type');

    debugPrint('[ApiService] position=$latitude,$longitude');

    debugPrint('[ApiService] destination=$destLat,$destLon');

    try {
      final requestBody = {
        'vehicleId': vehicleId,

        // IMPORTANT:
        // Backend expects emergencyType, not type.
        'emergencyType': type,

        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'heading': heading,

        // IMPORTANT:
        // Backend expects destination as an object.
        'destination': {'latitude': destLat, 'longitude': destLon},
      };

      debugPrint('[ApiService] START BODY: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 8));

      debugPrint('[ApiService] START STATUS: ${response.statusCode}');

      debugPrint('[ApiService] START RESPONSE: ${response.body}');

      // Backend successfully started emergency.
      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);

          if (decoded is! Map<String, dynamic>) {
            debugPrint('[ApiService] START ERROR: response is not an object');
            return null;
          }

          final corridorJson = decoded['corridor'];

          if (corridorJson == null) {
            debugPrint('[ApiService] START ERROR: corridor is null');
            return null;
          }

          if (corridorJson is! Map<String, dynamic>) {
            debugPrint('[ApiService] START ERROR: corridor has invalid format');
            return null;
          }

          try {
            final corridor = CorridorResult.fromJson(corridorJson);

            debugPrint('[ApiService] START SUCCESS: corridor parsed');

            return corridor;
          } catch (e, stackTrace) {
            debugPrint('[ApiService] CorridorResult parsing ERROR: $e');

            debugPrint('[ApiService] StackTrace: $stackTrace');

            return null;
          }
        } catch (e, stackTrace) {
          debugPrint('[ApiService] JSON parsing ERROR: $e');

          debugPrint('[ApiService] StackTrace: $stackTrace');

          return null;
        }
      }

      // Backend returned an error.
      debugPrint(
        '[ApiService] START FAILED '
        'HTTP ${response.statusCode}: ${response.body}',
      );

      return null;
    } catch (e, stackTrace) {
      debugPrint('[ApiService] startEmergency NETWORK ERROR: $e');

      debugPrint('[ApiService] StackTrace: $stackTrace');

      return null;
    }
  }

  // ------------------------------------------------------------
  // UPDATE EMERGENCY LOCATION
  // ------------------------------------------------------------

  Future<CorridorResult?> updateEmergencyLocation({
    required String vehicleId,
    required double latitude,
    required double longitude,
    double speed = 45.0,
    double heading = 90.0,
  }) async {
    final url = '$_baseUrl/emergency/location';

    debugPrint('[ApiService] UPDATE EMERGENCY LOCATION $url');

    try {
      final requestBody = {
        'vehicleId': vehicleId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'heading': heading,
      };

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 5));

      debugPrint('[ApiService] LOCATION STATUS: ${response.statusCode}');

      debugPrint('[ApiService] LOCATION RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          if (data is Map<String, dynamic> &&
              data['corridor'] != null &&
              data['corridor'] is Map<String, dynamic>) {
            return CorridorResult.fromJson(
              data['corridor'] as Map<String, dynamic>,
            );
          }
        } catch (e) {
          debugPrint(
            '[ApiService] updateEmergencyLocation '
            'JSON/PARSE ERROR: $e',
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('[ApiService] updateEmergencyLocation ERROR: $e');

      return null;
    }
  }

  // ------------------------------------------------------------
  // STOP EMERGENCY
  // ------------------------------------------------------------

  Future<bool> stopEmergency([String vehicleId = 'AMB001']) async {
    final url = '$_baseUrl/emergency/stop?vehicleId=$vehicleId';

    debugPrint('[ApiService] STOP EMERGENCY POST $url');

    try {
      final response = await http
          .post(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 5));

      debugPrint('[ApiService] STOP STATUS: ${response.statusCode}');

      debugPrint('[ApiService] STOP RESPONSE: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] stopEmergency ERROR: $e');

      return false;
    }
  }

  // ------------------------------------------------------------
  // FETCH NEARBY VEHICLES
  // ------------------------------------------------------------

  Future<List<Vehicle>> fetchNearbyVehicles({double radius = 800}) async {
    final url = '$_baseUrl/vehicles/nearby?radius=$radius';

    debugPrint('[ApiService] GET NEARBY $url');

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      debugPrint('[ApiService] NEARBY STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic> && data['vehicles'] is List) {
          final vehicles = (data['vehicles'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => Vehicle.fromJson(e))
              .toList();

          debugPrint('[ApiService] NEARBY VEHICLES: ${vehicles.length}');

          return vehicles;
        }
      }

      debugPrint('[ApiService] NEARBY FAILED: ${response.body}');
    } catch (e) {
      debugPrint('[ApiService] fetchNearbyVehicles ERROR: $e');
    }

    return [];
  }
}
