import 'package:vibration/vibration.dart';
import '../models/alert.dart';

class FCMNotificationService {
  static Future<void> triggerAlertFeedback(CorridorAlert alert) async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        if (alert.action == ActionType.MOVE_LEFT || alert.action == ActionType.MOVE_RIGHT) {
          // Strong double vibration warning pattern
          Vibration.vibrate(pattern: [0, 500, 200, 500]);
        } else {
          // Single warning vibration
          Vibration.vibrate(duration: 300);
        }
      }
    } catch (e) {
      print("Vibration feedback error: $e");
    }
  }
}
