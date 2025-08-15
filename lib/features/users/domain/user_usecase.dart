import '../data/user_repository.dart';
import '../../auth/data/auth_repository.dart';

class UserUseCase {
  UserUseCase({
    required UserRepository userRepository,
    required AuthRepository authRepository,
  }) : _userRepository = userRepository,
       _authRepository = authRepository;

  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  Stream<List<Map<String, dynamic>>> usersStream() {
    final currentUserId = _authRepository.currentUser?.uid;
    // Fetch all users and filter out the currently logged-in user on the client
    // to avoid Firestore isNotEqualTo/ordering quirks and index requirements.
    return _userRepository.usersStream().map((users) {
      if (currentUserId == null) return users;
      return users
          .where((u) => (u['uid'] ?? u['id']) != currentUserId)
          .toList(growable: false);
    });
  }

  String? get currentUserId => _authRepository.currentUser?.uid;
}
