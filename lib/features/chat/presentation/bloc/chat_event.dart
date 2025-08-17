part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatOpened extends ChatEvent {
  const ChatOpened(this.chatId);
  final String chatId;
}

class ChatSendText extends ChatEvent {
  const ChatSendText({required this.text, required this.senderId});
  final String text;
  final String senderId;
}

class ChatSendEmoji extends ChatEvent {
  const ChatSendEmoji({required this.emoji, required this.senderId});
  final String emoji;
  final String senderId;
}

class ChatDeleteMessage extends ChatEvent {
  const ChatDeleteMessage({required this.messageId});
  final String messageId;
}

class ChatPickAndUploadFile extends ChatEvent {
  const ChatPickAndUploadFile({required this.senderId, this.imageOnly = false});
  final String senderId;
  final bool imageOnly;
}

class ChatClearError extends ChatEvent {
  const ChatClearError();
}
