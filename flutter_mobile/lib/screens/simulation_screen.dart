import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simulation_provider.dart';
import '../widgets/corridor_map.dart';
import '../widgets/vehicle_stat_card.dart';

class SimulationScreen extends StatelessWidget {
  const SimulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SimulationProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Column(
        children: [
          // Simulation Header Bar
          Container(
            padding: const EdgeInsets.only(top: 44, left: 16, right: 16, bottom: 12),
            color: const Color(0xFF064E3B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      '🎮 Traffic Simulation Mode',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: provider.isSimulating ? const Color(0x3334D399) : const Color(0x3394A3B8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: provider.isSimulating ? const Color(0xFF34D399) : const Color(0xFF94A3B8)),
                  ),
                  child: Text(
                    provider.isSimulating ? 'SIMULATING' : 'STOPPED',
                    style: TextStyle(
                      color: provider.isSimulating ? const Color(0xFF34D399) : const Color(0xFFCBD5E1),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map Container
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: CorridorMap(
                centerLatitude: 13.0827,
                centerLongitude: 80.2707,
                corridor: provider.simulationCorridor,
                vehicles: provider.simulationVehicles,
                userVehicleId: 'AMB001',
                isEmergencyVehicle: true,
              ),
            ),
          ),

          // Control Panel
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Text(
                    'SIMULATED TRAFFIC DENSITY',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  Slider(
                    value: provider.activeVehicleCount.toDouble(),
                    min: 2,
                    max: 6,
                    divisions: 4,
                    label: '${provider.activeVehicleCount} Vehicles',
                    activeColor: const Color(0xFF2DD4BF),
                    onChanged: (val) => provider.setVehicleCount(val.round()),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.isSimulating ? const Color(0xFF475569) : const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: provider.isSimulating ? provider.stopSimulation : provider.startSimulation,
                      icon: Icon(provider.isSimulating ? Icons.stop : Icons.play_arrow, color: Colors.white),
                      label: Text(
                        provider.isSimulating ? 'STOP SIMULATION' : 'RUN MULTI-VEHICLE SIMULATION',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      VehicleStatCard(
                        title: 'Sim Vehicles',
                        value: '${provider.activeVehicleCount}',
                        icon: Icons.directions_car,
                        color: const Color(0xFF2DD4BF),
                      ),
                      VehicleStatCard(
                        title: 'Obstructing',
                        value: '${provider.simulationCorridor?.obstructingVehiclesCount ?? 0}',
                        icon: Icons.warning,
                        color: const Color(0xFFFBBF24),
                      ),
                      VehicleStatCard(
                        title: 'Instructed',
                        value: '${provider.simulationCorridor?.instructedToMoveCount ?? 0}',
                        icon: Icons.alt_route,
                        color: const Color(0xFF34D399),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
