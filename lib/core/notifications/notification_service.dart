import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../navigation/app_navigator.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Show a local notification for background data-only messages (Android)
  // iOS displays notifications automatically when payload contains the
  // notification block, and background handlers are not supported on iOS.
  final FlutterLocalNotificationsPlugin localPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );
  await localPlugin.initialize(initSettings);

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'chat_messages',
    'Chat Messages',
    importance: Importance.high,
    priority: Priority.high,
  );
  const NotificationDetails notifDetails = NotificationDetails(
    android: androidDetails,
  );

  final String title = message.notification?.title ?? 'New message';
  final String body = message.notification?.body ?? '';
  final String? chatId = message.data['chatId'] as String?;

  await localPlugin.show(0, title, body, notifDetails, payload: chatId);
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
    // Disable OS banners for iOS foreground; we control presentation via local notifications
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
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
      // Suppress notification if user is viewing that chat
      if (chatId != null && activeChatIdNotifier.value == chatId) {
        return;
      }
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
