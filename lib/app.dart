import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injector.dart';
import 'core/local/hive_manager.dart';
import 'core/notifications/notification_service.dart';
import 'core/navigation/app_navigator.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'features/users/presentation/pages/users_page.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await setupServiceLocator();
    await serviceLocator<HiveManager>().init();
    await serviceLocator<NotificationService>().init();
    setState(() => _isReady = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return BlocProvider(
      create: (_) => serviceLocator<AuthBloc>(),
      child: MaterialApp(
        title: 'Real-Time Chat',
        navigatorKey: appNavigatorKey,
        themeMode: ThemeMode.system,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        darkTheme: ThemeData.dark(useMaterial3: true),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => _AuthGate());
            case '/onboarding':
              return MaterialPageRoute(builder: (_) => const OnboardingPage());
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());
            case '/register':
              return MaterialPageRoute(builder: (_) => const RegisterPage());
            case '/users':
              return MaterialPageRoute(builder: (_) => const UsersPage());
            case '/chat':
              final chatId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => ChatPage(chatId: chatId),
              );
            default:
              return MaterialPageRoute(
                builder: (_) =>
                    const Scaffold(body: Center(child: Text('Not found'))),
              );
          }
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.isAuthenticated) {
          return const UsersPage();
        }
        return const LoginPage();
      },
    );
  }
}
