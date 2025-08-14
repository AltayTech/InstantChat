import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../navigation/app_navigator.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally left minimal; navigation happens when app opens.
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
    final androidImplementation = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'chat_messages',
        'Chat Messages',
        importance: Importance.high,
      ),
    );
    await _messaging.setAutoInitEnabled(true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('FCM token: ' + token);
    }
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM token refreshed: ' + newToken);
    });
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'New message';
      final body = message.notification?.body ?? '';
      final chatId = message.data['chatId'] as String?;
      showLocalNotification(title: title, body: body, payload: chatId);
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
