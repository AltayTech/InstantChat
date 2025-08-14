import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../navigation/app_navigator.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Show a notification only when the app is in background and the message
  // does not already contain a notification payload that the OS would show.
  // This prevents duplicate notifications when the FCM payload includes
  // the `notification` object.
  if (message.notification != null) {
    return;
  }

  final title = message.data['title'] as String? ?? 'New message';
  final body = message.data['body'] as String? ?? '';
  final chatId = message.data['chatId'] as String?;

  const androidDetails = AndroidNotificationDetails(
    'chat_messages',
    'Chat Messages',
    importance: Importance.high,
    priority: Priority.high,
  );
  const details = NotificationDetails(android: androidDetails);

  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();
  await localNotifications.show(0, title, body, details, payload: chatId);
}

class NotificationService {
  NotificationService({required FirebaseMessaging firebaseMessaging})
    : _messaging = firebaseMessaging;

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        openChatFromPayload(response.payload);
      },
    );

    await _messaging.requestPermission();
    // Do not present alerts when app is in foreground on iOS.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // Foreground: do not show a notification. UI will update via streams.
    FirebaseMessaging.onMessage.listen((message) {
      // Intentionally no-op to avoid notifications in foreground.
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final chatId = message.data['chatId'] as String?;
      openChatFromPayload(chatId);
    });
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      final chatId = initial.data['chatId'] as String?;
      openChatFromPayload(chatId);
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _local.show(0, title, body, details, payload: payload);
  }
}
