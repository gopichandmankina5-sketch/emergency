import 'dart:async';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/corridor.dart';
import '../services/api_service.dart';

class SimulationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isSimulating = false;
  int _activeVehicleCount = 6;
  CorridorResult? _simulationCorridor;
  List<Vehicle> _simulationVehicles = [];
  Timer? _simulationTimer;

  bool get isSimulating => _isSimulating;
  int get activeVehicleCount => _activeVehicleCount;
  CorridorResult? get simulationCorridor => _simulationCorridor;
  List<Vehicle> get simulationVehicles => _simulationVehicles;

  void setVehicleCount(int count) {
    _activeVehicleCount = count;
    notifyListeners();
  }

  Future<void> startSimulation() async {
    _isSimulating = true;
    notifyListeners();

    // Register simulated traffic vehicles V101-V106
    final baseVehicles = [
      {'id': 'V101', 'lat': 13.0850, 'lon': 80.2707, 'speed': 35.0, 'heading': 90.0},
      {'id': 'V102', 'lat': 13.0830, 'lon': 80.2710, 'speed': 30.0, 'heading': 90.0},
      {'id': 'V103', 'lat': 13.0835, 'lon': 80.2715, 'speed': 28.0, 'heading': 90.0},
      {'id': 'V104', 'lat': 13.0840, 'lon': 80.2730, 'speed': 40.0, 'heading': 90.0},
      {'id': 'V105', 'lat': 13.0860, 'lon': 80.2690, 'speed': 45.0, 'heading': 270.0},
      {'id': 'V106', 'lat': 13.0870, 'lon': 80.2740, 'speed': 25.0, 'heading': 90.0},
    ];

    for (int i = 0; i < _activeVehicleCount && i < baseVehicles.length; i++) {
      final v = baseVehicles[i];
      await _apiService.registerVehicle(
        vehicleId: v['id'] as String,
        latitude: v['lat'] as double,
        longitude: v['lon'] as double,
      );
    }

    _simulationCorridor = await _apiService.startEmergency(
      vehicleId: 'AMB001',
      type: 'AMBULANCE',
      latitude: 13.0800,
      longitude: 80.2680,
      destLat: 13.1000,
      destLon: 80.3000,
    );

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final corridor = await _apiService.fetchCorridor('AMB001');
      _simulationCorridor = corridor;
      final nearby = await _apiService.fetchNearbyVehicles();
      _simulationVehicles = nearby;
      notifyListeners();
    });
  }

  Future<void> stopSimulation() async {
    _isSimulating = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    await _apiService.stopEmergency('AMB001');
    notifyListeners();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
