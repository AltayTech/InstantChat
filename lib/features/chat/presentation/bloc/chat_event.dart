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

class ChatDeleteMessage extends ChatEvent {
  const ChatDeleteMessage({required this.messageId});
  final String messageId;
}
