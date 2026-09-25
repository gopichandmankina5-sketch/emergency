import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../providers/simulation_provider.dart';
import '../widgets/corridor_map.dart';
import '../widgets/simulation_controls.dart';

class SimulationScreen extends StatelessWidget {
  const SimulationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SimulationProvider>(context);
    final corridor = provider.corridorResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🎮 Interactive Traffic Corridor Simulator"),
        backgroundColor: Colors.teal.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: CorridorMapWidget(
              center: const LatLng(13.0800, 80.2680),
              corridor: corridor,
              vehicles: provider.simulatedVehicles,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Total Vehicles: ${corridor?.totalNearbyVehicles ?? 0}",
                    style: const TextStyle(color: Colors.white70)),
                Text("Obstructing: ${corridor?.obstructingVehiclesCount ?? 0}",
                    style: const TextStyle(color: Colors.orangeAccent)),
                Text("Instructed Move: ${corridor?.instructedToMoveCount ?? 0}",
                    style: const TextStyle(color: Colors.greenAccent)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SimulationControlsWidget(
              isRunning: provider.isSimulationRunning,
              trafficDensity: provider.trafficDensityCount,
              emergencySpeed: provider.emergencySpeedKmh,
              onDensityChanged: provider.setTrafficDensity,
              onSpeedChanged: provider.setEmergencySpeed,
              onToggleSimulation: provider.isSimulationRunning
                  ? provider.stopSimulation
                  : provider.runEmergencySimulation,
            ),
          )
        ],
      ),
    );
  }
}
