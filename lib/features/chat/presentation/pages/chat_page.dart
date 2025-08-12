import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/di/injector.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../presentation/bloc/chat_bloc.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.chatId});
  final String chatId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<ChatBloc>()..add(ChatOpened(widget.chatId)),
      child: Builder(
        builder: (innerContext) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        if (state.isLoading && state.messages.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state.messages.isEmpty) {
                          return const Center(child: Text('No messages yet'));
                        }
                        return ListView.builder(
                          reverse: true,
                          controller: _scrollController,
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final msg = state.messages[index];
                            final isMine =
                                msg['senderId'] ==
                                context.read<AuthBloc>().state.user?.uid;
                            final ts = msg['createdAt'];
                            String time = '';
                            if (ts is DateTime) {
                              time = DateFormat('HH:mm').format(ts);
                            } else if (ts is Timestamp) {
                              time = DateFormat('HH:mm').format(ts.toDate());
                            }
                            return Align(
                              alignment: isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer
                                      : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      msg['text'] ?? '',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      time,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Message',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              final text = _controller.text.trim();
                              if (text.isEmpty) return;
                              final uid = innerContext
                                  .read<AuthBloc>()
                                  .state
                                  .user!
                                  .uid;
                              innerContext.read<ChatBloc>().add(
                                ChatSendText(text: text, senderId: uid),
                              );
                              _controller.clear();
                            },
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
