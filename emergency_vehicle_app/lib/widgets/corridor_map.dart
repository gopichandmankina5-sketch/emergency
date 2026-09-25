import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/corridor.dart';
import '../models/vehicle.dart';

class CorridorMap extends StatelessWidget {
  final double centerLatitude;
  final double centerLongitude;
  final CorridorResult? corridor;
  final List<Vehicle> vehicles;
  final String userVehicleId;

  const CorridorMap({
    super.key,
    required this.centerLatitude,
    required this.centerLongitude,
    this.corridor,
    this.vehicles = const [],
    this.userVehicleId = 'AMB001',
  });

  @override
  Widget build(BuildContext context) {
    final centerLatLng = LatLng(
      centerLatitude != 0 ? centerLatitude : 13.0800,
      centerLongitude != 0 ? centerLongitude : 80.2680,
    );

    final routePoints = corridor?.predictedRoute.map((p) => p.toLatLng()).toList() ?? [];
    final polygonPoints = corridor?.corridorPolygon.map((p) => p.toLatLng()).toList() ?? [];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: centerLatLng,
          initialZoom: 15.5,
          minZoom: 10.0,
          maxZoom: 19.0,
        ),
        children: [
          // Online OpenStreetMap Tile Layer
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.emergencycorridor.mobile',
          ),

          // Dynamic Emergency Corridor Polygon Boundary Layer
          if (polygonPoints.length >= 3)
            PolygonLayer(
              polygons: [
                Polygon(
                  points: polygonPoints,
                  color: const Color(0x33EF4444),
                  borderColor: const Color(0xFFEF4444),
                  borderStrokeWidth: 2.5,
                ),
              ],
            ),

          // Predicted Emergency Vector Route Line Layer
          if (routePoints.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  color: const Color(0xFF38BDF8),
                  strokeWidth: 4.5,
                ),
              ],
            ),

          // Markers Layer
          MarkerLayer(
            markers: [
              // Emergency Vehicle Center Marker
              Marker(
                point: centerLatLng,
                width: 100,
                height: 40,
                child: _buildVehicleMarker(
                  isEv: true,
                  title: userVehicleId,
                ),
              ),

              // Surrounding Traffic Vehicles
              ...vehicles.where((v) => v.vehicleId != userVehicleId).map((v) {
                final isEv = v.isEmergency || v.vehicleId.startsWith('AMB');
                return Marker(
                  point: LatLng(v.latitude, v.longitude),
                  width: 80,
                  height: 36,
                  child: _buildVehicleMarker(
                    isEv: isEv,
                    title: v.vehicleId,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleMarker({
    required bool isEv,
    required String title,
  }) {
    final bgColor = isEv ? const Color(0xFFDC2626) : const Color(0xFF334155);
    final borderColor = isEv ? const Color(0xFFFEF08A) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isEv ? Icons.medical_services : Icons.directions_car,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
