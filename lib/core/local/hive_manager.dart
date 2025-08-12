import 'package:hive_flutter/hive_flutter.dart';

class HiveManager {
  static const String messagesBoxPrefix = 'messages_';

  Future<void> init() async {
    await Hive.initFlutter();
  }

  Future<Box<Map>> openMessagesBox(String chatId) async {
    return Hive.openBox<Map>(messagesBoxPrefix + chatId);
  }

  Future<void> cacheMessages({
    required String chatId,
    required List<Map> messages,
  }) async {
    final box = await openMessagesBox(chatId);
    await box.clear();
    for (final msg in messages) {
      await box.add(msg);
    }
  }

  Future<List<Map>> readCachedMessages(String chatId) async {
    final box = await openMessagesBox(chatId);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
