import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('[FcmService] Handling background message: ${message.messageId}');
  } catch (e) {
    debugPrint('[FcmService] Background handler warning: $e');
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      if (_messaging != null) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        NotificationSettings settings = await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        debugPrint('[FcmService] Permission status: ${settings.authorizationStatus}');
      }

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(initSettings);

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'emergency_corridor_channel',
        'Emergency Dispatch Channel',
        description: 'Notifications for emergency vehicle dispatchers',
        importance: Importance.max,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      if (_messaging != null) {
        _fcmToken = await _messaging!.getToken();
        debugPrint('[FcmService] Native FCM Token: $_fcmToken');

        _messaging!.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('[FcmService] FCM Token refreshed: $newToken');
        });
      }
    } catch (e) {
      debugPrint('[FcmService] Initialization warning: $e');
    }
  }
}
