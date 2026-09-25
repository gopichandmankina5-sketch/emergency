import 'package:flutter/material.dart';
import '../providers/emergency_provider.dart';

class ConnectionBadge extends StatelessWidget {
  final ConnectionStateEnum state;
  final String statusText;
  final Color badgeColor;

  const ConnectionBadge({
    super.key,
    required this.state,
    required this.statusText,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
