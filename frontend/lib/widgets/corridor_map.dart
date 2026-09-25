import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/corridor.dart';
import '../models/vehicle.dart';

class CorridorMapWidget extends StatelessWidget {
  final LatLng center;
  final CorridorResult? corridor;
  final List<Vehicle> vehicles;

  const CorridorMapWidget({
    Key? key,
    required this.center,
    this.corridor,
    this.vehicles = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [];

    // Emergency vehicle marker
    markers.add(
      Marker(
        point: center,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.local_hospital,
          color: Colors.redAccent,
          size: 36,
        ),
      ),
    );

    // Nearby vehicle markers
    for (var v in vehicles) {
      markers.add(
        Marker(
          point: LatLng(v.latitude, v.longitude),
          width: 30,
          height: 30,
          child: Column(
            children: [
              Icon(
                Icons.directions_car,
                color: v.locationEnabled ? Colors.cyanAccent : Colors.grey,
                size: 20,
              ),
              Text(
                v.vehicleId,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Corridor polyline points
    List<LatLng> polylinePoints = corridor?.predictedRoute
            .map((pt) => LatLng(pt.latitude, pt.longitude))
            .toList() ??
        [];

    // Polygon points for clearance corridor
    List<LatLng> polygonPoints = corridor?.corridorPolygon
            .map((pt) => LatLng(pt.latitude, pt.longitude))
            .toList() ??
        [];

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.emergency_corridor_app',
        ),
        if (polygonPoints.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: polygonPoints,
                color: Colors.red.withOpacity(0.25),
                borderColor: Colors.redAccent,
                borderStrokeWidth: 2,
                isFilled: true,
              ),
            ],
          ),
        if (polylinePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                strokeWidth: 4.0,
                color: Colors.amber,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
