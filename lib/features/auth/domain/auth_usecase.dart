import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../data/auth_repository.dart';

class AuthUseCase {
  AuthUseCase({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;

  Stream<fb_auth.User?> observeAuth() => _repository.authStateChanges();

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    await _repository.register(email: email, password: password, name: name);
  }

  Future<void> login({required String email, required String password}) async {
    await _repository.login(email: email, password: password);
  }

  Future<void> logout() => _repository.logout();

  fb_auth.User? get currentUser => _repository.currentUser;
}
