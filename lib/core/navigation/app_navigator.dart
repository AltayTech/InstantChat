import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
// This key is used to access the app's navigator from anywhere in the app
void openChatFromPayload(String? payload) {
  if (payload == null || payload.isEmpty) return;
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;
  navigator.pushNamed('/chat', arguments: payload);
}

// Tracks the chat the user is currently viewing so we can suppress
// foreground notifications for that specific conversation.
final ValueNotifier<String?> activeChatIdNotifier = ValueNotifier<String?>(
  null,
);
// This notifier is used to track the active chat ID across the app.
void setActiveChatId(String? chatId) {
  activeChatIdNotifier.value = chatId;
}
