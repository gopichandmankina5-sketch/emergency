import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import * as Haptics from 'expo-haptics';
import { Platform } from 'react-native';
import { CorridorAlert } from '../models/alert';

// Configure notification behavior
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

class NotificationService {
  private lastAlertTimestamp: string | null = null;
  private lastAlertAction: string | null = null;

  async registerForPushNotificationsAsync(): Promise<string | null> {
    let token: string | null = null;

    if (Platform.OS === 'android') {
      await Notifications.setNotificationChannelAsync('emergency_alerts', {
        name: 'Emergency Corridor Alerts',
        importance: Notifications.AndroidImportance.MAX,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: '#FF231F7C',
      });
    }

    if (Device.isDevice) {
      const { status: existingStatus } = await Notifications.getPermissionsAsync();
      let finalStatus = existingStatus;
      if (existingStatus !== 'granted') {
        const { status } = await Notifications.requestPermissionsAsync();
        finalStatus = status;
      }
      if (finalStatus !== 'granted') {
        console.warn('[NotificationService] Notification permission not granted!');
        return null;
      }
      try {
        // Fetch native Android FCM device token directly for FastAPI backend
        const deviceTokenResponse = await Notifications.getDevicePushTokenAsync();
        token = deviceTokenResponse.data;
        console.log('[NotificationService] Native Android FCM device token obtained successfully.');
      } catch (e) {
        console.warn('[NotificationService] Native Android FCM device token error:', e);
        token = null;
      }
    } else {
      console.warn('[NotificationService] Physical Android device required for native FCM push notifications.');
      token = null;
    }

    return token;
  }

  addNotificationListeners(
    onNotificationReceived?: (notification: Notifications.Notification) => void,
    onNotificationResponse?: (response: Notifications.NotificationResponse) => void
  ) {
    const receivedSubscription = Notifications.addNotificationReceivedListener((notification) => {
      console.log('[NotificationService] Remote/Local notification received:', notification);
      if (onNotificationReceived) {
        onNotificationReceived(notification);
      }
    });

    const responseSubscription = Notifications.addNotificationResponseReceivedListener((response) => {
      console.log('[NotificationService] Notification interaction response:', response);
      if (onNotificationResponse) {
        onNotificationResponse(response);
      }
    });

    return () => {
      receivedSubscription.remove();
      responseSubscription.remove();
    };
  }

  async triggerAlertFeedback(alert: CorridorAlert) {
    // Avoid repeatedly notifying/vibrating if the action and timestamp have not changed
    if (this.lastAlertTimestamp === alert.timestamp && this.lastAlertAction === alert.action) {
      return;
    }

    this.lastAlertTimestamp = alert.timestamp;
    this.lastAlertAction = alert.action;

    if (alert.action === 'NO_ALERT') {
      return;
    }

    try {
      // Trigger Haptic Vibration
      if (alert.action === 'MOVE_LEFT' || alert.action === 'MOVE_RIGHT') {
        await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
      } else if (alert.action === 'SLOW_DOWN') {
        await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
      } else {
        await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      }
    } catch (e) {
      // Haptics might not be supported on web/emulator
      console.log('[NotificationService] Haptics not available on this platform');
    }

    try {
      // Present Local In-App Notification
      await Notifications.scheduleNotificationAsync({
        content: {
          title: `🚨 EMERGENCY VEHICLE APPROACHING`,
          body: `ACTION: ${alert.actionText}\nDistance: ${Math.round(alert.distance)} m | ETA: ${Math.round(alert.eta)} s`,
          data: { alert },
          sound: true,
        },
        trigger: null, // Display immediately
      });
    } catch (e) {
      console.warn('[NotificationService] Error scheduling local notification:', e);
    }
  }

  resetAlertTracking() {
    this.lastAlertTimestamp = null;
    this.lastAlertAction = null;
  }
}

export const notificationService = new NotificationService();
