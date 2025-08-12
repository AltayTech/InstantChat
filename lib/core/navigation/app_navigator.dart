import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void openChatFromPayload(String? payload) {
  if (payload == null || payload.isEmpty) return;
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;
  navigator.pushNamed('/chat', arguments: payload);
}
