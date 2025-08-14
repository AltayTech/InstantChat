import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/navigation/app_navigator.dart';
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
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    setActiveChatId(widget.chatId);
    _scrollController.addListener(() {
      final shouldShow = _scrollController.position.pixels > 200;
      if (shouldShow != _showScrollToBottom) {
        setState(() => _showScrollToBottom = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    setActiveChatId(null);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDateHeader(DateTime dateOnly) {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final yesterdayOnly = todayOnly.subtract(const Duration(days: 1));
    if (dateOnly == todayOnly) return 'Today';
    if (dateOnly == yesterdayOnly) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(dateOnly);
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
                        return Stack(
                          children: [
                            ListView.builder(
                              reverse: true,
                              controller: _scrollController,
                              itemCount: state.messages.length,
                              itemBuilder: (context, index) {
                                final msg = state.messages[index];
                                final isMine =
                                    msg['senderId'] ==
                                    context.read<AuthBloc>().state.user?.uid;
                                final ts = msg['createdAt'];
                                DateTime createdAt;
                                if (ts is DateTime) {
                                  createdAt = ts;
                                } else if (ts is Timestamp) {
                                  createdAt = ts.toDate();
                                } else {
                                  createdAt = DateTime.now();
                                }
                                final time = DateFormat(
                                  'HH:mm',
                                ).format(createdAt);

                                String? dateHeaderLabel;
                                DateTime? currentDateOnly = DateTime(
                                  createdAt.year,
                                  createdAt.month,
                                  createdAt.day,
                                );
                                if (index == state.messages.length - 1) {
                                  dateHeaderLabel = _formatDateHeader(
                                    currentDateOnly,
                                  );
                                } else {
                                  final next =
                                      state.messages[index + 1]['createdAt'];
                                  DateTime nextDate;
                                  if (next is DateTime) {
                                    nextDate = next;
                                  } else if (next is Timestamp) {
                                    nextDate = next.toDate();
                                  } else {
                                    nextDate = createdAt;
                                  }
                                  final nextOnly = DateTime(
                                    nextDate.year,
                                    nextDate.month,
                                    nextDate.day,
                                  );
                                  if (nextOnly != currentDateOnly) {
                                    dateHeaderLabel = _formatDateHeader(
                                      currentDateOnly,
                                    );
                                  }
                                }
                                final borderRadius = BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(isMine ? 12 : 2),
                                  bottomRight: Radius.circular(isMine ? 2 : 12),
                                );
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (dateHeaderLabel != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.surfaceVariant,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              dateHeaderLabel,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelMedium,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Align(
                                      alignment: isMine
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.75,
                                        ),
                                        child: GestureDetector(
                                          onLongPress: isMine
                                              ? () async {
                                                  final confirmed =
                                                      await showDialog<bool>(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Text(
                                                            'Delete message?',
                                                          ),
                                                          content: const Text(
                                                            'This will delete the message for everyone.',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    ctx,
                                                                  ).pop(false),
                                                              child: const Text(
                                                                'Cancel',
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    ctx,
                                                                  ).pop(true),
                                                              child: const Text(
                                                                'Delete',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                  if (confirmed == true) {
                                                    context
                                                        .read<ChatBloc>()
                                                        .add(
                                                          ChatDeleteMessage(
                                                            messageId:
                                                                msg['id']
                                                                    as String,
                                                          ),
                                                        );
                                                  }
                                                }
                                              : null,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isMine
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                              borderRadius: borderRadius,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
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
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            if (_showScrollToBottom)
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: FloatingActionButton.small(
                                  onPressed: () {
                                    _scrollController.animateTo(
                                      0,
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                  child: const Icon(Icons.keyboard_arrow_down),
                                ),
                              ),
                          ],
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
                              textCapitalization: TextCapitalization.sentences,
                              minLines: 1,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'Message',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onSubmitted: (_) => _handleSend(innerContext),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Emoji',
                            onPressed: () => _openEmojiPicker(innerContext),
                            icon: const Icon(Icons.emoji_emotions_outlined),
                          ),
                          const SizedBox(width: 4),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _controller,
                            builder: (context, value, _) {
                              final canSend = value.text.trim().isNotEmpty;
                              return IconButton.filled(
                                onPressed: canSend
                                    ? () => _handleSend(innerContext)
                                    : null,
                                icon: const Icon(Icons.send),
                              );
                            },
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

  void _handleSend(BuildContext innerContext) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final uid = innerContext.read<AuthBloc>().state.user!.uid;
    innerContext.read<ChatBloc>().add(ChatSendText(text: text, senderId: uid));
    _controller.clear();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openEmojiPicker(BuildContext innerContext) async {
    final selected = await showModalBottomSheet<String>(
      context: innerContext,
      showDragHandle: true,
      builder: (ctx) {
        final emojis = [
          '😀',
          '😁',
          '😂',
          '🤣',
          '😊',
          '😍',
          '😘',
          '😎',
          '🤩',
          '😇',
          '👍',
          '👏',
          '🙏',
          '🔥',
          '🎉',
          '💯',
          '✅',
          '❌',
          '🤝',
          '🥳',
          '😢',
          '😡',
          '🤔',
          '😅',
          '🙌',
          '😴',
          '😱',
          '🤗',
          '🤤',
          '👀',
        ];
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: emojis.length,
          itemBuilder: (_, i) => InkWell(
            onTap: () => Navigator.of(ctx).pop(emojis[i]),
            child: Center(
              child: Text(emojis[i], style: const TextStyle(fontSize: 28)),
            ),
          ),
        );
      },
    );
    if (selected == null) return;
    final uid = innerContext.read<AuthBloc>().state.user!.uid;
    innerContext.read<ChatBloc>().add(
      ChatSendEmoji(emoji: selected, senderId: uid),
    );
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}
