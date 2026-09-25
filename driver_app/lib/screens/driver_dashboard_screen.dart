import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../widgets/corridor_map.dart';
import '../widgets/connection_badge.dart';
import '../widgets/vehicle_stat_card.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> with WidgetsBindingObserver {
  late TextEditingController _idController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final provider = Provider.of<DriverProvider>(context, listen: false);
    _idController = TextEditingController(text: provider.vehicleId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[DriverDashboardScreen] AppLifecycleState changed to: $state');
    final provider = Provider.of<DriverProvider>(context, listen: false);
    if (state == AppLifecycleState.resumed && provider.isRegistered) {
      provider.handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DriverProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Column(
        children: [
          // Driver App Header Bar
          Container(
            padding: const EdgeInsets.only(top: 44, left: 16, right: 16, bottom: 12),
            color: const Color(0xFF1E1B4B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      '🚗 Driver Alert Mode',
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
                ConnectionBadge(isRegistered: provider.isRegistered),
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
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACTION: ${provider.activeAlert!.actionText}',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: provider.acknowledgeAlert,
                      child: const Text(
                        'ACKNOWLEDGE & CLEAR LANE',
                        style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // OpenStreetMap View
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
              ),
            ),
          ),

          // Telemetry & Notification Panel
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
                  // Vehicle ID Entry & Connect Button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _idController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'DRIVER VEHICLE ID',
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

                  // Switches
                  Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          title: const Text('Live GPS', style: TextStyle(color: Colors.white, fontSize: 12)),
                          value: provider.isLiveGpsMode,
                          onChanged: provider.toggleLiveGpsMode,
                          activeTrackColor: const Color(0xFF059669),
                        ),
                      ),
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          title: const Text('Share Location', style: TextStyle(color: Colors.white, fontSize: 12)),
                          value: provider.locationSharingEnabled,
                          onChanged: provider.toggleLocationSharing,
                          activeTrackColor: const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Stat Cards
                  Row(
                    children: [
                      VehicleStatCard(
                        title: 'Speed',
                        value: '${provider.speed.round()} km/h',
                        icon: Icons.speed,
                        color: const Color(0xFF818CF8),
                      ),
                      VehicleStatCard(
                        title: 'Obstruction Score',
                        value: '${provider.activeAlert?.obstructionScore.round() ?? 0}%',
                        icon: Icons.shield,
                        color: const Color(0xFFFBBF24),
                      ),
                      VehicleStatCard(
                        title: 'Target Action',
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
