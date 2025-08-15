import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/local/hive_manager.dart';

class ChatRepository {
  ChatRepository({
    required FirebaseFirestore firestore,
    required HiveManager hiveManager,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _hive = hiveManager,
       _storage = storage;

  final FirebaseFirestore _firestore;
  final HiveManager _hive;
  final FirebaseStorage _storage;

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
    await _ensureChatDocumentExists(chatId);
    await _firestore.collection('chats').doc(chatId).collection('messages').add(
      {
        ...message,
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
      },
    );
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<String> uploadFile({
    required String chatId,
    required String senderId,
    required File file,
    required String filename,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage
        .ref()
        .child('chats')
        .child(chatId)
        .child(
          DateTime.now().millisecondsSinceEpoch.toString() + '_' + filename,
        );
    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: contentType),
    );
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) {
          onProgress((s.bytesTransferred / s.totalBytes) * 100);
        }
      });
    }
    await uploadTask.whenComplete(() {});
    return ref.getDownloadURL();
  }

  Future<List<Map>> readCached({required String chatId}) =>
      _hive.readCachedMessages(chatId);

  Future<void> cache({required String chatId, required List<Map> messages}) =>
      _hive.cacheMessages(chatId: chatId, messages: messages);

  Future<void> _ensureChatDocumentExists(String chatId) async {
    final docRef = _firestore.collection('chats').doc(chatId);
    final doc = await docRef.get();
    if (doc.exists) {
      // Touch updatedAt to keep recency; avoid overriding participants if present
      await docRef.set({
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    // Infer participants from chatId pattern: "uidA_uidB"
    final parts = chatId.split('_');
    final participants = parts.length == 2 ? parts : <String>[];
    await docRef.set({
      'participants': participants,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
