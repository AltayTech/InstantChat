import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injector.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../presentation/bloc/users_bloc.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<UsersBloc>()..add(const UsersStarted()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Users'),
          actions: [
            IconButton(
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              if (!authState.isAuthenticated) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: BlocBuilder<UsersBloc, UsersState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.separated(
                  itemCount: state.users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = state.users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['photoUrl'] != null
                            ? CachedNetworkImageProvider(user['photoUrl'])
                            : null,
                        child: user['photoUrl'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user['name'] ?? user['email'] ?? 'User'),
                      subtitle: Text(
                        (user['isOnline'] == true) ? 'Online' : 'Offline',
                      ),
                      onTap: () {
                        final String currentUserId = context
                            .read<AuthBloc>()
                            .state
                            .user!
                            .uid;
                        final String otherId = user['uid'] as String;
                        final chatId = [currentUserId, otherId]..sort();
                        Navigator.of(
                          context,
                        ).pushNamed('/chat', arguments: chatId.join('_'));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
