import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _otherUserUid;

  @override
  void initState() {
    super.initState();
    setActiveChatId(widget.chatId);
    final parts = widget.chatId.split('_');
    final currentUid = context.read<AuthBloc>().state.user?.uid;
    if (parts.length == 2 && currentUid != null) {
      _otherUserUid = parts.first == currentUid ? parts.last : parts.first;
    } else if (parts.isNotEmpty) {
      _otherUserUid = parts.firstWhere(
        (p) => p != currentUid,
        orElse: () => parts.first,
      );
    }
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
            appBar: AppBar(
              titleSpacing: 0,
              title: _otherUserUid == null
                  ? const Text('Chat')
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('uid', isEqualTo: _otherUserUid)
                          .limit(1)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.docs.isNotEmpty == true
                            ? snapshot.data!.docs.first.data()
                            : null;
                        final displayName =
                            (data?['name'] as String?) ??
                            (data?['email'] as String?) ??
                            'Chat';
                        //  I add profile avatar and it is not used in this project, but can be used for future features
                        final photoUrl = data?['photoUrl'] as String?;
                        final isOnline = data?['isOnline'] == true;
                        return Row(
                          children: [
                            Hero(
                              tag: 'avatar_' + (_otherUserUid ?? ''),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundImage: photoUrl != null
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    isOnline ? 'Online' : 'Offline',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: isOnline
                                              ? Colors.green
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
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
                                                        .tertiaryContainer
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .surfaceVariant,
                                              borderRadius: borderRadius,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _MessageContent(msg: msg),
                                                const SizedBox(height: 6),
                                                Text(
                                                  time,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: isMine
                                                            ? Theme.of(context)
                                                                  .colorScheme
                                                                  .onTertiaryContainer
                                                                  .withOpacity(
                                                                    0.8,
                                                                  )
                                                            : Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant
                                                                  .withOpacity(
                                                                    0.8,
                                                                  ),
                                                      ),
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
                          BlocListener<ChatBloc, ChatState>(
                            listenWhen: (prev, curr) =>
                                prev.errorMessage != curr.errorMessage,
                            listener: (context, state) {
                              final msg = state.errorMessage;
                              if (msg != null) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(SnackBar(content: Text(msg)));
                                context.read<ChatBloc>().add(
                                  const ChatClearError(),
                                );
                              }
                            },
                            child: const SizedBox.shrink(),
                          ),
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
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
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
                          IconButton(
                            tooltip: 'Attach',
                            onPressed: () =>
                                _openAttachmentPicker(innerContext),
                            icon: const Icon(Icons.attach_file),
                          ),
                          BlocBuilder<ChatBloc, ChatState>(
                            buildWhen: (p, c) =>
                                p.uploadProgress != c.uploadProgress,
                            builder: (context, state) {
                              final progress = state.uploadProgress;
                              if (progress == null)
                                return const SizedBox(width: 0, height: 0);
                              return SizedBox(
                                width: 64,
                                height: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress / 100,
                                  ),
                                ),
                              );
                            },
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

  Future<void> _openAttachmentPicker(BuildContext innerContext) async {
    final action = await showModalBottomSheet<_AttachmentAction>(
      context: innerContext,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Photo'),
              onTap: () => Navigator.of(ctx).pop(_AttachmentAction.image),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text('File'),
              onTap: () => Navigator.of(ctx).pop(_AttachmentAction.file),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null) return;
    final uid = innerContext.read<AuthBloc>().state.user!.uid;
    innerContext.read<ChatBloc>().add(
      ChatPickAndUploadFile(
        senderId: uid,
        imageOnly: action == _AttachmentAction.image,
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.msg});

  final Map<String, dynamic> msg;

  @override
  Widget build(BuildContext context) {
    final type = msg['type'] as String? ?? 'text';
    if (type == 'image' && msg['fileUrl'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          msg['fileUrl'] as String,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackFileTile(msg: msg),
        ),
      );
    }
    if (type == 'file' && msg['fileUrl'] != null) {
      return _FallbackFileTile(msg: msg);
    }
    return Text(
      msg['text'] ?? '',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

enum _AttachmentAction { image, file }

class _FallbackFileTile extends StatelessWidget {
  const _FallbackFileTile({required this.msg});

  final Map<String, dynamic> msg;

  @override
  Widget build(BuildContext context) {
    final fileName = (msg['fileName'] as String?) ?? 'Attachment';
    final fileUrl = (msg['fileUrl'] as String?) ?? '';
    final size = (msg['fileSize'] as int?) ?? 0;
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(fileUrl);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_outlined),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (size > 0)
                  Text(
                    _formatBytes(size),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    double value = bytes.toDouble();
    int i = 0;
    while (value >= 1024 && i < suffixes.length - 1) {
      value /= 1024;
      i++;
    }
    return value.toStringAsFixed(1) + ' ' + suffixes[i];
  }
}
