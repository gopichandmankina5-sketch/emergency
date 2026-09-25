import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle.dart';
import '../models/alert.dart';
import '../models/corridor.dart';

class ApiService {
  // Configurable base URL. Default localhost; can be set to host IP for physical phones.
  static String baseUrl = "http://localhost:8000/api";

  static void setBackendUrl(String url) {
    if (!url.startsWith("http")) {
      baseUrl = "http://$url/api";
    } else {
      baseUrl = url.endsWith("/api") ? url : "$url/api";
    }
  }

  Future<bool> registerVehicle(String vehicleId, {bool isEmergency = false, String? type, String? fcmToken}) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/vehicles/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "vehicleId": vehicleId,
          "isEmergency": isEmergency,
          "emergencyType": type,
          "fcmToken": fcmToken ?? "mock_token_$vehicleId",
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registerFCMToken(String vehicleId, String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/vehicles/fcm-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "vehicleId": vehicleId,
          "fcmToken": fcmToken,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
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
      final response = await http.post(
        Uri.parse("$baseUrl/vehicles/location"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "vehicleId": vehicleId,
          "latitude": latitude,
          "longitude": longitude,
          "speed": speed,
          "heading": heading,
          "locationEnabled": locationEnabled,
          "lastUpdated": DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
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
      final response = await http.post(
        Uri.parse("$baseUrl/emergency/start"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "vehicleId": vehicleId,
          "type": type,
          "latitude": latitude,
          "longitude": longitude,
          "speed": speed,
          "heading": heading,
          "destination": {"latitude": destLat, "longitude": destLon},
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CorridorResult.fromJson(data['corridor']);
      }
    } catch (e) {
      print("Start emergency error: $e");
    }
    return null;
  }

  Future<CorridorResult?> fetchCorridor(String emergencyId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/emergency/$emergencyId/corridor"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CorridorResult.fromJson(data);
      }
    } catch (e) {
      print("Fetch corridor error: $e");
    }
    return null;
  }

  Future<CorridorAlert?> fetchAlertForVehicle(String vehicleId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/alerts/$vehicleId"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['hasAlert'] == true && data['latestAlert'] != null) {
          return CorridorAlert.fromJson(data['latestAlert']);
        }
      }
    } catch (e) {
      print("Fetch alert error: $e");
    }
    return null;
  }

  Future<List<Vehicle>> fetchNearbyVehicles() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/vehicles/nearby?radius=800"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['vehicles'] as List<dynamic>;
        return list.map((v) => Vehicle.fromJson(v)).toList();
      }
    } catch (e) {
      print("Fetch nearby vehicles error: $e");
    }
    return [];
  }
}
