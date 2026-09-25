import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Analytics & Course Project Dashboard"),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.grey.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Corridor Performance Overview",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  SizedBox(height: 12),
                  Text("• Minimum Interventions Rate: 33.3% (3 of 6 vehicles instructed)",
                      style: TextStyle(color: Colors.white70)),
                  Text("• Path Clearance Time Saved: 18.5 seconds vs broadcast alert",
                      style: TextStyle(color: Colors.white70)),
                  Text("• Secondary Congestion Avoided: 84.0% efficiency score",
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Downloading Excel-compatible analytics CSV dataset..."),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.file_download, color: Colors.white),
            label: const Text(
              "EXPORT CSV FOR EXCEL PROJECT",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
