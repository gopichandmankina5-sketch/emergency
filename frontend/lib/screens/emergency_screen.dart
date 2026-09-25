import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../providers/emergency_provider.dart';
import '../widgets/corridor_map.dart';
import '../widgets/vehicle_stat_card.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmergencyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🚨 Emergency Vehicle Mode"),
        backgroundColor: Colors.red.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: CorridorMapWidget(
              center: LatLng(provider.latitude, provider.longitude),
              corridor: provider.activeCorridor,
              vehicles: provider.nearbyVehicles,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    DropdownButton<String>(
                      value: provider.emergencyType,
                      dropdownColor: Colors.grey.shade900,
                      items: ["AMBULANCE", "FIRE", "POLICE"]
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) provider.setEmergencyType(val);
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.isEmergencyActive ? Colors.grey : Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: provider.isEmergencyActive
                          ? provider.stopEmergencyMission
                          : provider.startEmergencyMission,
                      icon: Icon(provider.isEmergencyActive ? Icons.stop : Icons.local_hospital),
                      label: Text(provider.isEmergencyActive ? "STOP EMERGENCY" : "START EMERGENCY"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: VehicleStatCardWidget(
                        title: "Nearby Vehicles",
                        value: "${provider.activeCorridor?.totalNearbyVehicles ?? 0}",
                        icon: Icons.directions_car,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: VehicleStatCardWidget(
                        title: "Obstructing",
                        value: "${provider.activeCorridor?.obstructingVehiclesCount ?? 0}",
                        icon: Icons.warning_amber,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: VehicleStatCardWidget(
                        title: "Instructed Move",
                        value: "${provider.activeCorridor?.instructedToMoveCount ?? 0}",
                        icon: Icons.alt_route,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
