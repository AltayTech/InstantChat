import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/chat_usecase.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required ChatUseCase chatUseCase})
    : _useCase = chatUseCase,
      super(const ChatState.initial()) {
    on<ChatOpened>(_onOpened);
    on<ChatSendText>(_onSendText);
  }

  final ChatUseCase _useCase;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  Future<void> _onOpened(ChatOpened event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true, chatId: event.chatId));
    final cached = await _useCase.readCached(event.chatId);
    if (cached.isNotEmpty) {
      emit(
        state.copyWith(
          isLoading: false,
          messages: cached.cast<Map<String, dynamic>>(),
        ),
      );
    }
    await _subscription?.cancel();
    // Keep the handler alive and await stream emissions to avoid emit-after-complete
    await emit.forEach<List<Map<String, dynamic>>>(
      _useCase.streamMessages(event.chatId),
      onData: (messages) =>
          state.copyWith(isLoading: false, messages: messages),
      onError: (_, __) => state.copyWith(isLoading: false),
    );
  }

  Future<void> _onSendText(ChatSendText event, Emitter<ChatState> emit) async {
    await _useCase.sendText(
      chatId: state.chatId!,
      senderId: event.senderId,
      text: event.text,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
