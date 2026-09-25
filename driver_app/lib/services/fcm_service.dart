import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

const String kEmergencyChannelId = 'emergency_corridor_loud_v3';
const String kEmergencyChannelV2Id = 'emergency_corridor_loud_v2';
const String kEmergencyChannelName = '🚨 Emergency Corridor Alerts';
const String kEmergencyChannelDesc =
    'Critical high-priority loud audible notifications for emergency vehicle maneuvers';

int _bgNotificationCounter = 0;
int _fgNotificationCounter = 0;
final Set<String> _processedMessageIds = <String>{};

Future<bool> checkActiveEmergencyState(String vehicleId) async {
  debugPrint('[EmergencyNotification] Checking active emergency state');
  try {
    const String baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://emergency-nzyw.onrender.com/api',
    );
    final url = Uri.parse('$baseUrl/alerts/$vehicleId');
    final response = await http.get(url).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['hasAlert'] == true) {
        final alerts = data['alerts'];
        final latestAlert = data['latestAlert'];
        if ((alerts is List && alerts.isNotEmpty) ||
            (latestAlert is Map<String, dynamic> && latestAlert['active'] != false)) {
          debugPrint('[EmergencyNotification] Active emergency = true');
          return true;
        }
      }
    }
    debugPrint('[EmergencyNotification] Active emergency = false');
    return false;
  } catch (e) {
    debugPrint('[EmergencyNotification] Error checking active emergency state: $e');
    debugPrint('[EmergencyNotification] Active emergency = true (fallback)');
    return true;
  }
}

Future<void> _ensureNotificationChannelsCreated(
    FlutterLocalNotificationsPlugin localNotifications) async {
  final androidPlugin = localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    for (final channelId in [kEmergencyChannelId, kEmergencyChannelV2Id]) {
      debugPrint('[EmergencyNotification] Creating channel: $channelId');
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        kEmergencyChannelName,
        description: kEmergencyChannelDesc,
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('emergency_alert'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        showBadge: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }
    debugPrint('[EmergencyNotification] Notification channels created successfully');
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('[FCM] Background message received');
    debugPrint('[EmergencyNotification] App state = background');
    debugPrint('[EmergencyNotification] FCM received');

    String action = message.data['action'] ?? '';
    String evId = message.data['emergencyVehicleId'] ?? 'AMB001';
    String vId = message.data['vehicleId'] ?? 'V102';
    String messageId = message.messageId ?? '';
    String alertId = message.data['alertId'] ?? '';
    String timestamp = message.data['timestamp'] ?? DateTime.now().toIso8601String();
    String msgType = message.data['type'] ?? 'EMERGENCY_CORRIDOR_ALERT';
    String title = message.notification?.title ??
        message.data['title'] ??
        '🚨 EMERGENCY VEHICLE APPROACHING';
    String body = message.notification?.body ??
        message.data['body'] ??
        message.data['actionText'] ??
        'Please clear the emergency corridor';

    debugPrint('[EmergencyNotification] messageId = $messageId');
    debugPrint('[EmergencyNotification] alertId = $alertId');
    debugPrint('[EmergencyNotification] timestamp = $timestamp');
    debugPrint('[EmergencyNotification] emergencyVehicleId = $evId');
    debugPrint('[EmergencyNotification] vehicleId = $vId');
    debugPrint('[EmergencyNotification] action = $action');
    debugPrint('[EmergencyNotification] type = $msgType');

    if (action.isEmpty || action == 'NO_ALERT') {
      debugPrint('[EmergencyNotification] SUPPRESSED - NO_ALERT');
      return;
    }

    String dedupKey = alertId.isNotEmpty ? alertId : messageId;
    if (dedupKey.isNotEmpty) {
      if (_processedMessageIds.contains(dedupKey)) {
        debugPrint('[EmergencyNotification] SUPPRESSED - duplicate message');
        return;
      }
      _processedMessageIds.add(dedupKey);
      if (_processedMessageIds.length > 100) {
        _processedMessageIds.remove(_processedMessageIds.first);
      }
    }

    final bool isActive = await checkActiveEmergencyState(vId);
    if (!isActive) {
      debugPrint('[EmergencyNotification] SUPPRESSED - no active emergency');
      return;
    }

    debugPrint('[EmergencyNotification] ACCEPTED - active emergency alert');

    if (message.notification != null) {
      debugPrint('[EmergencyNotification] Android native FCM displayed notification (skipping duplicate local notification)');
      return;
    }

    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await localNotifications
        .initialize(const InitializationSettings(android: androidSettings));

    await _ensureNotificationChannelsCreated(localNotifications);

    final int notificationId =
        ((DateTime.now().millisecondsSinceEpoch + (_bgNotificationCounter++)) & 0x7FFFFFFF);

    debugPrint('[EmergencyNotification] Creating local emergency notification');
    debugPrint('[EmergencyNotification] notificationId = $notificationId');
    debugPrint('[EmergencyNotification] channel = emergency_corridor_loud_v3');
    debugPrint('[EmergencyNotification] sound = emergency_alert');

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
      notificationId,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );

    debugPrint('[EmergencyNotification] local notification displayed');
  } catch (e, stack) {
    debugPrint('[EmergencyNotification] ERROR:\n$e\n$stack');
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

      await _ensureNotificationChannelsCreated(_localNotifications);

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        bool? granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('[FcmService] Android POST_NOTIFICATIONS permission granted: $granted');
        if (granted == false) {
          debugPrint('[FcmService] WARNING: Android POST_NOTIFICATIONS permission NOT granted!');
        }
      }

      if (_messaging != null) {
        _fcmToken = await _messaging!.getToken();
        if (_fcmToken != null && _fcmToken!.isNotEmpty) {
          debugPrint('[FCM] Token obtained');
          debugPrint('[FcmService] Native FCM Token obtained');
          await _saveTokenLocally(_fcmToken!);
          _onTokenChanged?.call(_fcmToken!);
        }

        _messaging!.onTokenRefresh.listen((newToken) async {
          debugPrint('[FcmService] FCM Token refreshed');
          await _saveTokenLocally(newToken);
          _onTokenChanged?.call(newToken);
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          debugPrint('[EmergencyNotification] App state = foreground');
          debugPrint('[EmergencyNotification] FCM received');

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
          String messageId = message.messageId ?? '';
          String alertId = message.data['alertId'] ?? '';
          String timestamp = message.data['timestamp'] ?? DateTime.now().toIso8601String();
          String msgType = message.data['type'] ?? 'EMERGENCY_CORRIDOR_ALERT';

          debugPrint('[EmergencyNotification] messageId = $messageId');
          debugPrint('[EmergencyNotification] alertId = $alertId');
          debugPrint('[EmergencyNotification] timestamp = $timestamp');
          debugPrint('[EmergencyNotification] emergencyVehicleId = $evId');
          debugPrint('[EmergencyNotification] vehicleId = $vId');
          debugPrint('[EmergencyNotification] action = $action');
          debugPrint('[EmergencyNotification] type = $msgType');

          if (action.isEmpty || action == 'NO_ALERT') {
            debugPrint('[EmergencyNotification] SUPPRESSED - NO_ALERT');
            return;
          }

          String dedupKey = alertId.isNotEmpty ? alertId : messageId;
          if (dedupKey.isNotEmpty) {
            if (_processedMessageIds.contains(dedupKey)) {
              debugPrint('[EmergencyNotification] SUPPRESSED - duplicate message');
              return;
            }
            _processedMessageIds.add(dedupKey);
            if (_processedMessageIds.length > 100) {
              _processedMessageIds.remove(_processedMessageIds.first);
            }
          }

          final bool isActive = await checkActiveEmergencyState(vId);
          if (!isActive) {
            debugPrint('[EmergencyNotification] SUPPRESSED - no active emergency');
            return;
          }

          debugPrint('[EmergencyNotification] ACCEPTED - active emergency alert');

          if (shouldNotify(evId, vId, action)) {
            triggerHapticAlert(action);
            await showLocalNotification(
              title: title,
              body: body,
              messageId: messageId,
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
    String? messageId,
    int? notificationId,
  }) async {
    try {
      final int finalId = notificationId ??
          ((DateTime.now().millisecondsSinceEpoch + (_fgNotificationCounter++)) & 0x7FFFFFFF);

      debugPrint('[EmergencyNotification] Creating local emergency notification');
      debugPrint('[EmergencyNotification] notificationId = $finalId');
      debugPrint('[EmergencyNotification] channel = emergency_corridor_loud_v3');
      debugPrint('[EmergencyNotification] sound = emergency_alert');

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
        finalId,
        title,
        body,
        details,
      );

      debugPrint('[EmergencyNotification] local notification displayed');
    } catch (e, stack) {
      debugPrint('[EmergencyNotification] ERROR:\n$e\n$stack');
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
