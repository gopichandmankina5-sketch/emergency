import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

const String kEmergencyChannelId = 'emergency_corridor_loud_v2';
const String kEmergencyChannelName = '🚨 Emergency Corridor Alerts';
const String kEmergencyChannelDesc =
    'Critical high-priority loud audible notifications for emergency vehicle maneuvers';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('[FCM] Background message received');
    debugPrint('[EmergencyNotification] FCM alert received');

    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await localNotifications
        .initialize(const InitializationSettings(android: androidSettings));

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      kEmergencyChannelId,
      kEmergencyChannelName,
      description: kEmergencyChannelDesc,
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('emergency_alert'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      showBadge: true,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    String title = message.notification?.title ??
        message.data['title'] ??
        '🚨 EMERGENCY VEHICLE APPROACHING';
    String body = message.notification?.body ??
        message.data['body'] ??
        message.data['actionText'] ??
        'Please clear the emergency corridor';
    String action = message.data['action'] ?? '';

    if (action.isEmpty || action == 'NO_ALERT') {
      await localNotifications.cancelAll();
      debugPrint('[EmergencyNotification] NO_ALERT/empty action received in background, cancelled notifications');
      return;
    }

    debugPrint('[EmergencyNotification] Playing emergency sound');
    debugPrint('[EmergencyNotification] Showing high-priority notification');
    debugPrint('[FCM] Emergency notification displayed');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      kEmergencyChannelId,
      kEmergencyChannelName,
      channelDescription: kEmergencyChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('emergency_alert'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await localNotifications.show(
      1001,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  } catch (e) {
    debugPrint('[FcmService] Background handler exception: $e');
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  void Function(String token)? _onTokenChanged;

  void setOnTokenChangedCallback(void Function(String token) callback) {
    _onTokenChanged = callback;
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      callback(_fcmToken!);
    }
  }

  Future<void> _saveTokenLocally(String token) async {
    _fcmToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      debugPrint('[FcmService] Saved FCM token locally');
    } catch (e) {
      debugPrint('[FcmService] Error saving FCM token locally: $e');
    }
  }

  Future<String?> getSavedToken() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) return _fcmToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      _fcmToken = prefs.getString('fcm_token');
    } catch (e) {
      debugPrint('[FcmService] Error getting saved FCM token: $e');
    }
    return _fcmToken;
  }

  final Map<String, DateTime> _lastNotificationTimes = {};

  bool shouldNotify(
    String emergencyVehicleId,
    String vehicleId,
    String action, {
    Duration cooldown = const Duration(seconds: 15),
    DateTime? now,
  }) {
    if (action.isEmpty || action == 'NO_ALERT') return false;
    final key = '${emergencyVehicleId}_${vehicleId}_$action';
    final currentTime = now ?? DateTime.now();

    final lastTime = _lastNotificationTimes[key];
    if (lastTime != null && currentTime.difference(lastTime) < cooldown) {
      final elapsed = currentTime.difference(lastTime).inSeconds;
      debugPrint('[FcmService] Notification suppressed for key: $key (${elapsed}s elapsed < ${cooldown.inSeconds}s cooldown)');
      return false;
    }

    _lastNotificationTimes[key] = currentTime;
    debugPrint('[FcmService] Notification allowed for key: $key at $currentTime');
    return true;
  }

  void resetNotificationState() {
    _lastNotificationTimes.clear();
    debugPrint('[FcmService] Notification state reset');
  }

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      if (_messaging != null) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

        NotificationSettings settings = await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          criticalAlert: true,
          announcement: true,
        );

        debugPrint('[FcmService] FCM Permission status: ${settings.authorizationStatus}');
      }

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(initSettings);

      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        kEmergencyChannelId,
        kEmergencyChannelName,
        description: kEmergencyChannelDesc,
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('emergency_alert'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        showBadge: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        bool? granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('[FcmService] Android POST_NOTIFICATIONS permission granted: $granted');
      }

      if (_messaging != null) {
        _fcmToken = await _messaging!.getToken();
        if (_fcmToken != null && _fcmToken!.isNotEmpty) {
          debugPrint('[FcmService] Native FCM Token obtained');
          await _saveTokenLocally(_fcmToken!);
          _onTokenChanged?.call(_fcmToken!);
        }

        _messaging!.onTokenRefresh.listen((newToken) async {
          debugPrint('[FcmService] FCM Token refreshed');
          await _saveTokenLocally(newToken);
          _onTokenChanged?.call(newToken);
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('[EmergencyNotification] FCM alert received');
          String title = message.notification?.title ??
              message.data['title'] ??
              '🚨 EMERGENCY VEHICLE APPROACHING';
          String body = message.notification?.body ??
              message.data['body'] ??
              message.data['actionText'] ??
              'Please clear the emergency corridor';
          String action = message.data['action'] ?? '';
          String evId = message.data['emergencyVehicleId'] ?? 'AMB001';
          String vId = message.data['vehicleId'] ?? 'V102';

          if (action.isNotEmpty && action != 'NO_ALERT' && shouldNotify(evId, vId, action)) {
            showLocalNotification(
              title: title,
              body: body,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[FcmService] Initialization warning: $e');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    try {
      debugPrint('[EmergencyNotification] Playing emergency sound');
      debugPrint('[EmergencyNotification] Showing high-priority notification');
      debugPrint('[FCM] Emergency notification displayed');

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        kEmergencyChannelId,
        kEmergencyChannelName,
        channelDescription: kEmergencyChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('emergency_alert'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        ticker: 'Emergency Corridor Instruction',
      );
      final NotificationDetails details =
          NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        1001,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('[FcmService] Local notification error: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('[EmergencyNotification] Alert acknowledged');
    } catch (e) {
      debugPrint('[FcmService] cancelAllNotifications error: $e');
    }
  }

  Future<void> triggerHapticAlert(String action) async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        if (action == 'MOVE_LEFT' || action == 'MOVE_RIGHT') {
          Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
        } else if (action == 'SLOW_DOWN') {
          Vibration.vibrate(duration: 800);
        } else {
          Vibration.vibrate(duration: 250);
        }
      }
    } catch (e) {
      debugPrint('[FcmService] Vibration warning: $e');
    }
  }
}
