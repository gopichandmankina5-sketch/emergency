import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FcmService] Handling background message: ${message.messageId}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('[FcmService] Permission status: ${settings.authorizationStatus}');

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(initSettings);

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'emergency_corridor_channel',
        'Emergency Corridor Alerts',
        description: 'Critical notifications for emergency vehicle maneuvers',
        importance: Importance.max,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _fcmToken = await _messaging.getToken();
      debugPrint('[FcmService] Native FCM Token: $_fcmToken');

      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('[FcmService] FCM Token refreshed: $newToken');
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FcmService] Foreground message received: ${message.notification?.title}');
        if (message.notification != null) {
          showLocalNotification(
            title: message.notification!.title ?? '🚨 EMERGENCY CORRIDOR ALERT',
            body: message.notification!.body ?? 'Please maneuver carefully',
          );
        }
      });
    } catch (e) {
      debugPrint('[FcmService] Initialization warning: $e');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'emergency_corridor_channel',
        'Emergency Corridor Alerts',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );
      const NotificationDetails details = NotificationDetails(android: androidDetails);
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('[FcmService] Local notification error: $e');
    }
  }

  Future<void> triggerHapticAlert(String action) async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        if (action == 'MOVE_LEFT' || action == 'MOVE_RIGHT') {
          Vibration.vibrate(pattern: [0, 250, 200, 250]);
        } else if (action == 'SLOW_DOWN') {
          Vibration.vibrate(duration: 500);
        } else {
          Vibration.vibrate(duration: 150);
        }
      }
    } catch (e) {
      debugPrint('[FcmService] Vibration warning: $e');
    }
  }
}
