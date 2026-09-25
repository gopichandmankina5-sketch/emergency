import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../widgets/corridor_map.dart';
import '../widgets/vehicle_stat_card.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  late TextEditingController _idController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DriverProvider>(context, listen: false);
    _idController = TextEditingController(text: provider.vehicleId);
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DriverProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Column(
        children: [
          // Driver Header Bar
          Container(
            padding: const EdgeInsets.only(top: 44, left: 16, right: 16, bottom: 12),
            color: const Color(0xFF1E1B4B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      '🚗 Driver Mode',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF312E81),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        provider.vehicleId,
                        style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: provider.isRegistered ? const Color(0x3310B981) : const Color(0x33EF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: provider.isRegistered ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                  ),
                  child: Text(
                    provider.isRegistered ? 'REGISTERED' : 'UNREGISTERED',
                    style: TextStyle(
                      color: provider.isRegistered ? const Color(0xFF34D399) : const Color(0xFFF87171),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Maneuver Alert Banner
          if (provider.activeAlert != null && provider.activeAlert!.action != 'NO_ALERT')
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.redAccent, blurRadius: 8)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTION REQUIRED: ${provider.activeAlert!.actionText}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Distance: ${provider.activeAlert!.distance.round()} m | ETA: ${provider.activeAlert!.eta.round()} s',
                          style: const TextStyle(color: Color(0xFFFEF08A), fontSize: 11),
                        ),
                      ],
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
                centerLatitude: provider.latitude,
                centerLongitude: provider.longitude,
                corridor: provider.activeCorridor,
                vehicles: provider.nearbyVehicles,
                userVehicleId: provider.vehicleId,
                isEmergencyVehicle: false,
              ),
            ),
          ),

          // Control & Telemetry Panel
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
                  // Vehicle ID input & Register button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _idController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'VEHICLE ID',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: provider.setVehicleId,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: provider.registerVehicle,
                        child: const Text('CONNECT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // GPS Mode & Location sharing row
                  Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          title: const Text('Live GPS', style: TextStyle(color: Colors.white, fontSize: 12)),
                          value: provider.isLiveGpsMode,
                          onChanged: provider.toggleLiveGpsMode,
                          activeColor: const Color(0xFF34D399),
                        ),
                      ),
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          title: const Text('Share Loc', style: TextStyle(color: Colors.white, fontSize: 12)),
                          value: provider.locationSharingEnabled,
                          onChanged: provider.toggleLocationSharing,
                          activeColor: const Color(0xFF818CF8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Stat Cards
                  Row(
                    children: [
                      VehicleStatCard(
                        title: 'My Speed',
                        value: '${provider.speed.round()} km/h',
                        icon: Icons.speed,
                        color: const Color(0xFF818CF8),
                      ),
                      VehicleStatCard(
                        title: 'Obstruction',
                        value: '${provider.activeAlert?.obstructionScore.round() ?? 0}%',
                        icon: Icons.shield,
                        color: const Color(0xFFFBBF24),
                      ),
                      VehicleStatCard(
                        title: 'Action',
                        value: provider.activeAlert?.action ?? 'NO_ALERT',
                        icon: Icons.navigation,
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
