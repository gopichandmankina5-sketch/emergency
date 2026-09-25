import 'package:flutter/material.dart';
import '../models/alert.dart';

class AlertBannerWidget extends StatelessWidget {
  final CorridorAlert? alert;
  final bool locationEnabled;

  const AlertBannerWidget({
    Key? key,
    this.alert,
    required this.locationEnabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!locationEnabled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade900.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amberAccent, width: 2),
        ),
        child: Column(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 40),
            SizedBox(height: 8),
            Text(
              "🚨 EMERGENCY VEHICLE NEARBY",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 4),
            Text(
              "Precise emergency corridor instructions require location access.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (alert == null || alert!.action == ActionType.NO_ALERT) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
        ),
        child: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 36),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "PATH CLEAR - No active emergency corridor intervention required",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    Color bannerColor = Colors.red.shade900.withOpacity(0.95);
    IconData actionIcon = Icons.swap_horiz;

    if (alert!.action == ActionType.MOVE_LEFT) {
      actionIcon = Icons.arrow_back;
    } else if (alert!.action == ActionType.MOVE_RIGHT) {
      actionIcon = Icons.arrow_forward;
    } else if (alert!.action == ActionType.SLOW_DOWN) {
      actionIcon = Icons.speed;
      bannerColor = Colors.orange.shade900.withOpacity(0.95);
    } else if (alert!.action == ActionType.STAY) {
      actionIcon = Icons.pan_tool;
      bannerColor = Colors.blue.shade900.withOpacity(0.95);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.vibration, color: Colors.yellowAccent, size: 24),
              SizedBox(width: 8),
              Text(
                "🚨 EMERGENCY VEHICLE APPROACHING",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.yellowAccent),
              ),
            ],
          ),
          const Divider(color: Colors.white30, height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(actionIcon, size: 36, color: Colors.red.shade900),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Vehicle ID: ${alert!.vehicleId}",
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert!.actionText,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("Distance: ${alert!.distance.toStringAsFixed(0)} m",
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              Text("ETA: ${alert!.eta.toStringAsFixed(0)} sec",
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          )
        ],
      ),
    );
  }
}
