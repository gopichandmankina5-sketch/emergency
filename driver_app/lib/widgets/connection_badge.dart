import 'package:flutter/material.dart';

class ConnectionBadge extends StatelessWidget {
  final bool isRegistered;

  const ConnectionBadge({
    super.key,
    required this.isRegistered,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRegistered ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final text = isRegistered ? '🟢 REGISTERED' : '🔴 UNREGISTERED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
