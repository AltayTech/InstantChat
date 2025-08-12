import '../data/chat_repository.dart';

class ChatUseCase {
  ChatUseCase({required ChatRepository chatRepository})
    : _repository = chatRepository;

  final ChatRepository _repository;

  Stream<List<Map<String, dynamic>>> streamMessages(String chatId) =>
      _repository.messagesStream(chatId: chatId).map((messages) {
        // Ensure timestamps are present as DateTime for UI and cache
        return messages.map((m) {
          final data = Map<String, dynamic>.from(m);
          if (data['createdAt'] == null) {
            data['createdAt'] = DateTime.now();
          }
          return data;
        }).toList();
      });

  Future<void> sendText({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    await _repository.sendMessage(
      chatId: chatId,
      message: {'senderId': senderId, 'text': text, 'type': 'text'},
    );
  }

  Future<List<Map>> readCached(String chatId) =>
      _repository.readCached(chatId: chatId);
  Future<void> cache(String chatId, List<Map> messages) =>
      _repository.cache(chatId: chatId, messages: messages);
}
