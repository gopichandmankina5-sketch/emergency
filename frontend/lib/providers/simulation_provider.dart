import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/corridor.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';

class SimulationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isSimulationRunning = false;
  int _trafficDensityCount = 15;
  double _emergencySpeedKmh = 50.0;
  CorridorResult? _corridorResult;
  List<Vehicle> _simulatedVehicles = [];
  Timer? _simulationTimer;

  bool get isSimulationRunning => _isSimulationRunning;
  int get trafficDensityCount => _trafficDensityCount;
  double get emergencySpeedKmh => _emergencySpeedKmh;
  CorridorResult? get corridorResult => _corridorResult;
  List<Vehicle> get simulatedVehicles => _simulatedVehicles;

  void setTrafficDensity(int count) {
    _trafficDensityCount = count;
    notifyListeners();
  }

  void setEmergencySpeed(double speed) {
    _emergencySpeedKmh = speed;
    notifyListeners();
  }

  Future<void> runEmergencySimulation() async {
    _isSimulationRunning = true;
    notifyListeners();

    // Register emergency vehicle AMB001
    await _apiService.registerVehicle("AMB001", isEmergency: true, type: "AMBULANCE");

    // Register demo simulation vehicles V101..V106
    final demoVehicles = [
      {"id": "V101", "lat": 13.0850, "lon": 80.2650, "speed": 35.0, "heading": 90.0},
      {"id": "V102", "lat": 13.0815, "lon": 80.2695, "speed": 32.0, "heading": 90.0},
      {"id": "V103", "lat": 13.0818, "lon": 80.2698, "speed": 30.0, "heading": 90.0},
      {"id": "V104", "lat": 13.0820, "lon": 80.2700, "speed": 28.0, "heading": 90.0},
      {"id": "V105", "lat": 13.0825, "lon": 80.2710, "speed": 45.0, "heading": 270.0},
      {"id": "V106", "lat": 13.0830, "lon": 80.2715, "speed": 25.0, "heading": 90.0},
    ];

    for (var dv in demoVehicles) {
      await _apiService.registerVehicle(dv["id"] as String);
      await _apiService.updateVehicleLocation(
        vehicleId: dv["id"] as String,
        latitude: dv["lat"] as double,
        longitude: dv["lon"] as double,
        speed: dv["speed"] as double,
        heading: dv["heading"] as double,
      );
    }

    _corridorResult = await _apiService.startEmergency(
      vehicleId: "AMB001",
      type: "AMBULANCE",
      latitude: 13.0800,
      longitude: 80.2680,
      speed: _emergencySpeedKmh,
      heading: 90.0,
      destLat: 13.1000,
      destLon: 80.3000,
    );

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isSimulationRunning) {
        timer.cancel();
        return;
      }
      _corridorResult = await _apiService.fetchCorridor("AMB001");
      _simulatedVehicles = await _apiService.fetchNearbyVehicles();
      notifyListeners();
    });
  }

  void stopSimulation() {
    _isSimulationRunning = false;
    _simulationTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
