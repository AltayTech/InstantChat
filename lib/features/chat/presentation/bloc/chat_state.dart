part of 'chat_bloc.dart';

class ChatState extends Equatable {
  const ChatState({
    required this.messages,
    required this.isLoading,
    required this.chatId,
    required this.uploadProgress,
    required this.errorMessage,
  });

  const ChatState.initial()
    : messages = const [],
      isLoading = false,
      chatId = null,
      uploadProgress = null,
      errorMessage = null;

  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final String? chatId;
  final double? uploadProgress; // 0..100
  final String? errorMessage;

  ChatState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isLoading,
    String? chatId,
    double? uploadProgress,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) => ChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    chatId: chatId ?? this.chatId,
    uploadProgress: uploadProgress ?? this.uploadProgress,
    errorMessage: clearErrorMessage
        ? null
        : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [
    messages,
    isLoading,
    chatId,
    uploadProgress,
    errorMessage,
  ];
}
