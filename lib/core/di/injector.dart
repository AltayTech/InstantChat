import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/auth_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/chat/domain/chat_usecase.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/users/data/user_repository.dart';
import '../../features/users/domain/user_usecase.dart';
import '../../features/users/presentation/bloc/users_bloc.dart';
import '../local/hive_manager.dart';
import '../notifications/notification_service.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Firebase SDKs
  serviceLocator.registerLazySingleton<fb_auth.FirebaseAuth>(
    () => fb_auth.FirebaseAuth.instance,
  );
  serviceLocator.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  serviceLocator.registerLazySingleton<FirebaseMessaging>(
    () => FirebaseMessaging.instance,
  );
  serviceLocator.registerLazySingleton<FirebaseStorage>(
    () => FirebaseStorage.instance,
  );

  // Local storage
  serviceLocator.registerLazySingleton<HiveManager>(() => HiveManager());

  // Notifications
  serviceLocator.registerLazySingleton<NotificationService>(
    () => NotificationService(
      firebaseMessaging: serviceLocator<FirebaseMessaging>(),
    ),
  );

  // Repositories
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      auth: serviceLocator<fb_auth.FirebaseAuth>(),
      firestore: serviceLocator<FirebaseFirestore>(),
      messaging: serviceLocator<FirebaseMessaging>(),
    ),
  );
  serviceLocator.registerLazySingleton<UserRepository>(
    () => UserRepository(firestore: serviceLocator<FirebaseFirestore>()),
  );
  serviceLocator.registerLazySingleton<ChatRepository>(
    () => ChatRepository(
      firestore: serviceLocator<FirebaseFirestore>(),
      hiveManager: serviceLocator<HiveManager>(),
      storage: serviceLocator<FirebaseStorage>(),
    ),
  );

  // Use cases
  serviceLocator.registerLazySingleton<AuthUseCase>(
    () => AuthUseCase(repository: serviceLocator<AuthRepository>()),
  );
  serviceLocator.registerLazySingleton<UserUseCase>(
    () => UserUseCase(
      userRepository: serviceLocator<UserRepository>(),
      authRepository: serviceLocator<AuthRepository>(),
    ),
  );
  serviceLocator.registerLazySingleton<ChatUseCase>(
    () => ChatUseCase(chatRepository: serviceLocator<ChatRepository>()),
  );

  // Blocs - factories to get a fresh instance per injection
  serviceLocator.registerFactory<AuthBloc>(
    () => AuthBloc(serviceLocator<AuthUseCase>()),
  );
  serviceLocator.registerFactory<UsersBloc>(
    () => UsersBloc(userUseCase: serviceLocator<UserUseCase>()),
  );
  serviceLocator.registerFactory<ChatBloc>(
    () => ChatBloc(chatUseCase: serviceLocator<ChatUseCase>()),
  );
}
