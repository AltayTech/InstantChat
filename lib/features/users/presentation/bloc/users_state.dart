part of 'users_bloc.dart';

class UsersState extends Equatable {
  const UsersState({required this.users, required this.isLoading});

  const UsersState.initial() : users = const [], isLoading = false;

  final List<Map<String, dynamic>> users;
  final bool isLoading;

  UsersState copyWith({List<Map<String, dynamic>>? users, bool? isLoading}) =>
      UsersState(
        users: users ?? this.users,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props => [users, isLoading];
}
