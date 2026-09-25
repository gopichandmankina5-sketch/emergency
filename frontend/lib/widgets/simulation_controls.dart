import 'package:flutter/material.dart';

class SimulationControlsWidget extends StatelessWidget {
  final bool isRunning;
  final int trafficDensity;
  final double emergencySpeed;
  final ValueChanged<int> onDensityChanged;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onToggleSimulation;

  const SimulationControlsWidget({
    Key? key,
    required this.isRunning,
    required this.trafficDensity,
    required this.emergencySpeed,
    required this.onDensityChanged,
    required this.onSpeedChanged,
    required this.onToggleSimulation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Traffic Density (Vehicles):", style: TextStyle(color: Colors.white70)),
              Text("$trafficDensity", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
            ],
          ),
          Slider(
            value: trafficDensity.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            onChanged: (val) => onDensityChanged(val.toInt()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Emergency Vehicle Speed (km/h):", style: TextStyle(color: Colors.white70)),
              Text("${emergencySpeed.toInt()} km/h",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
            ],
          ),
          Slider(
            value: emergencySpeed,
            min: 20,
            max: 90,
            divisions: 7,
            onChanged: onSpeedChanged,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onToggleSimulation,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRunning ? Colors.redAccent : Colors.greenAccent.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(isRunning ? Icons.stop : Icons.play_arrow, color: Colors.white),
              label: Text(
                isRunning ? "STOP SIMULATION" : "RUN EMERGENCY SIMULATION",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }
}
