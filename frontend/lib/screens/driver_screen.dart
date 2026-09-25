import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../providers/driver_provider.dart';
import '../widgets/corridor_map.dart';
import '../widgets/alert_banner.dart';

class DriverScreen extends StatelessWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DriverProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🚗 Driver Mode"),
        backgroundColor: Colors.indigo.shade900,
        actions: [
          Row(
            children: [
              Text(
                provider.locationEnabled ? "GPS ON " : "GPS OFF ",
                style: TextStyle(
                  color: provider.locationEnabled ? Colors.greenAccent : Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: provider.locationEnabled,
                activeColor: Colors.greenAccent,
                onChanged: provider.toggleLocationPermission,
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: CorridorMapWidget(
              center: LatLng(provider.latitude, provider.longitude),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AlertBannerWidget(
              alert: provider.activeAlert,
              locationEnabled: provider.locationEnabled,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Vehicle ID: ${provider.vehicleId}", style: const TextStyle(color: Colors.white70)),
                Text("Speed: ${provider.speed.toInt()} km/h", style: const TextStyle(color: Colors.white70)),
                Text("Heading: ${provider.heading.toInt()}°", style: const TextStyle(color: Colors.white70)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
