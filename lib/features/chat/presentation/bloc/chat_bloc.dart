import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

import '../../domain/chat_usecase.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required ChatUseCase chatUseCase})
    : _useCase = chatUseCase,
      super(const ChatState.initial()) {
    on<ChatOpened>(_onOpened);
    on<ChatSendText>(_onSendText);
    on<ChatSendEmoji>(_onSendEmoji);
    on<ChatDeleteMessage>(_onDeleteMessage);
    on<ChatPickAndUploadFile>(_onPickAndUploadFile);
    on<ChatClearError>(_onClearError);
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

  Future<void> _onSendEmoji(
    ChatSendEmoji event,
    Emitter<ChatState> emit,
  ) async {
    await _useCase.sendEmoji(
      chatId: state.chatId!,
      senderId: event.senderId,
      emoji: event.emoji,
    );
  }

  Future<void> _onDeleteMessage(
    ChatDeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    final chatId = state.chatId;
    if (chatId == null) return;
    await _useCase.deleteMessage(chatId: chatId, messageId: event.messageId);
  }

  Future<void> _onPickAndUploadFile(
    ChatPickAndUploadFile event,
    Emitter<ChatState> emit,
  ) async {
    final chatId = state.chatId;
    if (chatId == null) return;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
      type: event.imageOnly ? FileType.image : FileType.any,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    if (picked.path == null) return;
    final file = File(picked.path!);
    final bytes = await file.length();
    if (bytes == 0) {
      emit(state.copyWith(errorMessage: 'Selected file is empty.'));
      return;
    }
    if (bytes > 50 * 1024 * 1024) {
      // 50MB guard
      emit(state.copyWith(errorMessage: 'File is too large (max 50 MB).'));
      return;
    }
    final filename = picked.name;
    final mimeType = lookupMimeType(picked.path!) ?? 'application/octet-stream';
    emit(state.copyWith(uploadProgress: 0, clearErrorMessage: true));
    try {
      final url = await _useCase.uploadFile(
        chatId: chatId,
        senderId: event.senderId,
        file: file,
        filename: filename,
        mimeType: mimeType,
        onProgress: (p) => emit(state.copyWith(uploadProgress: p)),
      );
      await _useCase.sendFile(
        chatId: chatId,
        senderId: event.senderId,
        url: url,
        filename: filename,
        bytes: bytes,
        mimeType: mimeType,
        displayType: mimeType.startsWith('image/') ? 'image' : 'file',
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Upload failed. Please try again.'));
    } finally {
      emit(state.copyWith(uploadProgress: null));
    }
  }

  void _onClearError(ChatClearError event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearErrorMessage: true));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
