import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/services/fcm_service.dart';
import 'package:driver_app/models/alert.dart';

void main() {
  group('Driver App Critical Notification & Alert Lifecycle Tests (13-21)', () {
    late FcmService fcmService;

    setUp(() {
      fcmService = FcmService();
      fcmService.resetNotificationState();
    });

    test('13. Opening Driver App with NO active emergency produces ZERO emergency notifications', () {
      final String action = '';
      final String evId = 'AMB001';
      final String vId = 'V102';

      final shouldNotify = fcmService.shouldNotify(evId, vId, action);
      expect(shouldNotify, isFalse, reason: 'No active emergency must produce zero notifications');
    });

    test('14. Historical allAlerts cannot trigger notification', () {
      final Map<String, dynamic> responseData = {
        'vehicleId': 'V102',
        'hasAlert': false,
        'alerts': <Map<String, dynamic>>[],
        'allAlerts': [
          {
            'vehicleId': 'V102',
            'emergencyVehicleId': 'AMB001',
            'action': 'MOVE_RIGHT',
            'actionText': 'MOVE RIGHT WHEN SAFE',
            'active': false,
            'timestamp': '2026-09-24T10:00:00Z'
          }
        ]
      };

      CorridorAlert? alert;
      if (responseData['hasAlert'] == true && responseData['alerts'] is List && (responseData['alerts'] as List).isNotEmpty) {
        alert = CorridorAlert.fromJson((responseData['alerts'] as List).last);
      }

      expect(alert, isNull);
      final String action = alert?.action ?? '';
      expect(fcmService.shouldNotify('AMB001', 'V102', action), isFalse);
    });

    test('15. hasAlert=false produces no notification', () {
      final Map<String, dynamic> responseData = {
        'vehicleId': 'V102',
        'hasAlert': false,
        'alerts': <Map<String, dynamic>>[]
      };

      CorridorAlert? alert;
      if (responseData['hasAlert'] == true && responseData['alerts'] is List && (responseData['alerts'] as List).isNotEmpty) {
        alert = CorridorAlert.fromJson((responseData['alerts'] as List).last);
      }

      expect(alert, isNull);
      expect(fcmService.shouldNotify('AMB001', 'V102', alert?.action ?? ''), isFalse);
    });

    test('16. Emergency start + active V102 alert produces notification', () {
      final startTime = DateTime(2026, 9, 24, 12, 0, 0);
      final allowed = fcmService.shouldNotify('AMB001', 'V102', 'MOVE_RIGHT', now: startTime);
      expect(allowed, isTrue);
    });

    test('17. Same active alert respects existing 15-second cooldown', () {
      final t0 = DateTime(2026, 9, 24, 12, 0, 0);
      fcmService.shouldNotify('AMB001', 'V102', 'MOVE_RIGHT', now: t0);

      final t5 = t0.add(const Duration(seconds: 5));
      final blockedAt5 = fcmService.shouldNotify('AMB001', 'V102', 'MOVE_RIGHT', now: t5);
      expect(blockedAt5, isFalse);

      final t15 = t0.add(const Duration(seconds: 15));
      final allowedAt15 = fcmService.shouldNotify('AMB001', 'V102', 'MOVE_RIGHT', now: t15);
      expect(allowedAt15, isTrue);
    });

    test('18. Emergency stop cancels/clears notification', () {
      final t0 = DateTime(2026, 9, 24, 12, 0, 0);
      fcmService.shouldNotify('AMB001', 'V102', 'MOVE_RIGHT', now: t0);

      // Emergency stops
      fcmService.resetNotificationState();
      
      final String actionAfterStop = 'NO_ALERT';
      expect(fcmService.shouldNotify('AMB001', 'V102', actionAfterStop), isFalse);
    });

    test('19. After stop, no further notification is produced', () {
      fcmService.resetNotificationState();
      expect(fcmService.shouldNotify('AMB001', 'V102', ''), isFalse);
      expect(fcmService.shouldNotify('AMB001', 'V102', 'NO_ALERT'), isFalse);
    });

    test('20. New emergency allows a fresh notification', () {
      final t0 = DateTime(2026, 9, 24, 12, 0, 0);
      fcmService.shouldNotify('AMB001', 'V102', 'MOVE_RIGHT', now: t0);

      // Emergency stops
      fcmService.resetNotificationState();

      // New emergency AMB002 starts
      final t2 = t0.add(const Duration(seconds: 2));
      final freshAllowed = fcmService.shouldNotify('AMB002', 'V102', 'MOVE_RIGHT', now: t2);
      expect(freshAllowed, isTrue);
    });

    test('21. NO_ALERT never produces notification', () {
      final blocked = fcmService.shouldNotify('AMB001', 'V102', 'NO_ALERT');
      expect(blocked, isFalse);
    });
  });
}
