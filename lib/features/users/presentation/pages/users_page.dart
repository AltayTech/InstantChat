import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injector.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../presentation/bloc/users_bloc.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<UsersBloc>()..add(const UsersStarted()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Users'),
          actions: [
            IconButton(
              tooltip: 'Logout',
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<UsersBloc, UsersState>(
                    builder: (context, state) {
                      if (state.isLoading && state.users.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final filteredUsers = state.users
                          .where((user) {
                            if (_query.isEmpty) return true;
                            final name = (user['name'] ?? '')
                                .toString()
                                .toLowerCase();
                            final email = (user['email'] ?? '')
                                .toString()
                                .toLowerCase();
                            return name.contains(_query) ||
                                email.contains(_query);
                          })
                          .toList(growable: false);

                      if (filteredUsers.isEmpty) {
                        return const Center(child: Text('No users found'));
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<UsersBloc>().add(const UsersStarted());
                          await Future<void>.delayed(
                            const Duration(milliseconds: 300),
                          );
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: filteredUsers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final bool isOnline = user['isOnline'] == true;
                            final String displayName =
                                user['name'] ?? user['email'] ?? 'User';
                            final String uid = user['uid'] as String;
                            final String? photoUrl =
                                user['photoUrl'] as String?;
                            return Card(
                              elevation: 0,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Hero(
                                      tag: 'avatar_' + uid,
                                      child: CircleAvatar(
                                        backgroundImage: photoUrl != null
                                            ? CachedNetworkImageProvider(
                                                photoUrl,
                                              )
                                            : null,
                                        child: photoUrl == null
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: isOnline
                                              ? Colors.green
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.outlineVariant,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  displayName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                subtitle: Text(
                                  isOnline ? 'Online' : 'Offline',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: isOnline
                                            ? Colors.green
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  final String currentUserId = context
                                      .read<AuthBloc>()
                                      .state
                                      .user!
                                      .uid;
                                  final String otherId = uid;
                                  final chatId = [currentUserId, otherId]
                                    ..sort();
                                  Navigator.of(context).pushNamed(
                                    '/chat',
                                    arguments: chatId.join('_'),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
