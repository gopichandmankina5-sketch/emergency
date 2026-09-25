import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emergency_provider.dart';
import '../widgets/corridor_map.dart';
import '../widgets/connection_badge.dart';
import '../widgets/vehicle_stat_card.dart';

class EmergencyDashboardScreen extends StatefulWidget {
  const EmergencyDashboardScreen({super.key});

  @override
  State<EmergencyDashboardScreen> createState() => _EmergencyDashboardScreenState();
}

class _EmergencyDashboardScreenState extends State<EmergencyDashboardScreen> {
  late TextEditingController _idController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<EmergencyProvider>(context, listen: false);
    _idController = TextEditingController(text: provider.emergencyVehicleId);
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmergencyProvider>(context);
    final types = ['AMBULANCE', 'FIRE', 'POLICE'];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Column(
        children: [
          // Emergency Header Bar
          Container(
            padding: const EdgeInsets.only(top: 44, left: 16, right: 16, bottom: 12),
            color: const Color(0xFF7F1D1D),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      '🚨 Emergency Dispatch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF991B1B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        provider.emergencyVehicleId,
                        style: const TextStyle(
                          color: Color(0xFFFEF08A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                ConnectionBadge(
                  state: provider.connectionState,
                  statusText: provider.connectionStatusText,
                  badgeColor: provider.connectionBadgeColor,
                ),
              ],
            ),
          ),

          // OpenStreetMap Container View
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: CorridorMap(
                centerLatitude: provider.latitude,
                centerLongitude: provider.longitude,
                corridor: provider.activeCorridor,
                vehicles: provider.nearbyVehicles,
                userVehicleId: provider.emergencyVehicleId,
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
                  // Vehicle ID entry row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _idController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'EMERGENCY VEHICLE ID',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: provider.setEmergencyVehicleId,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // GPS Mode Selector Row
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: provider.isLiveGpsMode ? const Color(0xFF34D399) : const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.isLiveGpsMode ? 'Real GPS Tracking (ON)' : 'Simulated GPS Stream',
                              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Switch(
                          value: provider.isLiveGpsMode,
                          onChanged: provider.toggleLiveGpsMode,
                          activeTrackColor: const Color(0xFF059669),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Emergency Type Selector
                  const Text(
                    'EMERGENCY DISPATCH TYPE',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: types.map((t) {
                      final selected = provider.emergencyType == t;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => provider.setEmergencyType(t),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? const Color(0xFFFCA5A5) : const Color(0xFF334155),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                t,
                                style: TextStyle(
                                  color: selected ? Colors.white : const Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Start / Stop Emergency Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.isEmergencyActive ? const Color(0xFF475569) : const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: provider.isEmergencyActive ? provider.stopEmergencyMission : provider.startEmergencyMission,
                      icon: Icon(
                        provider.isEmergencyActive ? Icons.stop : Icons.flash_on,
                        color: Colors.white,
                      ),
                      label: Text(
                        provider.isEmergencyActive ? 'STOP EMERGENCY MISSION' : 'START LIVE EMERGENCY',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Telemetry Stats Bar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Lat: ${provider.latitude.toStringAsFixed(4)}', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                        Text('Lon: ${provider.longitude.toStringAsFixed(4)}', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                        Text('Speed: ${provider.speed.round()} km/h', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Stat Cards
                  Row(
                    children: [
                      VehicleStatCard(
                        title: 'Nearby',
                        value: '${provider.activeCorridor?.totalNearbyVehicles ?? provider.nearbyVehicles.length}',
                        icon: Icons.directions_car,
                        color: const Color(0xFF38BDF8),
                      ),
                      VehicleStatCard(
                        title: 'Obstructing',
                        value: '${provider.activeCorridor?.obstructingVehiclesCount ?? 0}',
                        icon: Icons.warning,
                        color: const Color(0xFFFBBF24),
                      ),
                      VehicleStatCard(
                        title: 'Instructed',
                        value: '${provider.activeCorridor?.instructedToMoveCount ?? 0}',
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
