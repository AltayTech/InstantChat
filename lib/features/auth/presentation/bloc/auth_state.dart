part of 'auth_bloc.dart';

class AuthState extends Equatable {
  const AuthState._({this.user, this.isLoading = false, this.errorMessage});

  const AuthState.unauthenticated() : this._(user: null);

  const AuthState.authenticated(this.user)
    : isLoading = false,
      errorMessage = null;

  final fb_auth.User? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    fb_auth.User? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState._(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [user?.uid, isLoading, errorMessage];
}
