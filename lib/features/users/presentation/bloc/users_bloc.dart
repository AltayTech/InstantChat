import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/user_usecase.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc({required UserUseCase userUseCase})
    : _useCase = userUseCase,
      super(const UsersState.initial()) {
    on<UsersStarted>(_onStarted);
  }

  final UserUseCase _useCase;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  Future<void> _onStarted(UsersStarted event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoading: true));
    await _subscription?.cancel();
    // Keep the handler alive while listening to the stream to avoid emit-after-complete.
    await emit.forEach<List<Map<String, dynamic>>>(
      _useCase.usersStream(),
      onData: (users) => state.copyWith(isLoading: false, users: users),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
