part of 'chat_bloc.dart';

class ChatState extends Equatable {
  const ChatState({
    required this.messages,
    required this.isLoading,
    required this.chatId,
  });

  const ChatState.initial()
    : messages = const [],
      isLoading = false,
      chatId = null;

  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final String? chatId;

  ChatState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isLoading,
    String? chatId,
  }) => ChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    chatId: chatId ?? this.chatId,
  );

  @override
  List<Object?> get props => [messages, isLoading, chatId];
}
