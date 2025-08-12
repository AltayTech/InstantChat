import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/local/hive_manager.dart';

class ChatRepository {
  ChatRepository({
    required FirebaseFirestore firestore,
    required HiveManager hiveManager,
  }) : _firestore = firestore,
       _hive = hiveManager;

  final FirebaseFirestore _firestore;
  final HiveManager _hive;

  Stream<List<Map<String, dynamic>>> messagesStream({required String chatId}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required Map<String, dynamic> message,
  }) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').add(
      {
        ...message,
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
      },
    );
  }

  Future<List<Map>> readCached({required String chatId}) =>
      _hive.readCachedMessages(chatId);

  Future<void> cache({required String chatId, required List<Map> messages}) =>
      _hive.cacheMessages(chatId: chatId, messages: messages);
}
