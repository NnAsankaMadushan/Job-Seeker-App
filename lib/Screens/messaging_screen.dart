import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/models/message.dart';
import 'package:job_seeker_app/services/firebase_chat_service.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MessagingScreen extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? userImage;

  const MessagingScreen({
    super.key,
    required this.userId,
    this.userName,
    this.userImage,
  });

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen>
    with WidgetsBindingObserver {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<List<Message>>? _messagesSubscription;
  List<Message> _messages = [];
  final List<Message> _pendingMessages = [];
  bool _isLoading = true;
  String? _loadError;
  bool _isSending = false;
  bool _userIsAtBottom = true;
  String? _recipientPhone;
  bool _isLoadingRecipientPhone = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
    _loadRecipientPhone();
    _loadMessages();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    // Check if user is near the bottom (within 100 pixels)
    final isAtBottom = _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 100;

    if (_userIsAtBottom != isAtBottom) {
      setState(() {
        _userIsAtBottom = isAtBottom;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Mark messages as read when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      FirebaseChatService().markAsRead(widget.userId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _messagesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final chatService = FirebaseChatService();
      await _messagesSubscription?.cancel();

      // Ensure the conversation document exists before listening for messages.
      await chatService.ensureConversationExists(widget.userId);

      // Listen to messages stream
      _messagesSubscription = chatService.getMessages(widget.userId).listen(
        (messages) {
          if (!mounted) return;

          setState(() {
            _messages = messages;
            // Remove pending messages that have now been delivered (matching by content and sender)
            _pendingMessages.removeWhere((pending) => messages.any((m) =>
                m.content == pending.content &&
                m.senderId == pending.senderId));
            _isLoading = false;
            _loadError = null;
          });

          // Mark messages as read whenever messages update
          chatService.markAsRead(widget.userId);

          // Auto-scroll to bottom only if user is already at the bottom OR it's the very first load
          if (_isLoading || _userIsAtBottom) {
            _scrollToBottom();
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        onError: (error, stackTrace) {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
            _loadError = error.toString();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading messages: $error')),
          );
        },
      );

      // Create the parent conversation doc in the background so it does not
      // block the first messages snapshot if Firestore is slow or offline.
      unawaited(chatService.ensureConversationExists(widget.userId));

      // Mark messages as read immediately when screen opens
      await chatService.markAsRead(widget.userId);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    final currentUserId = FirebaseAuthService().currentUser?.uid ?? '';

    // 1. Create temporary message for Optimistic UI
    final tempMessage = Message(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUserId,
      senderName: 'Me',
      receiverId: widget.userId,
      content: messageText,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // 2. Update UI immediately
    _messageController.clear();
    setState(() {
      _pendingMessages.add(tempMessage);
      _isSending = true;
      _userIsAtBottom = true; // Force scroll for user's own message
    });
    _scrollToBottom();

    // 3. Send in background
    try {
      final result = await FirebaseChatService().sendMessage(
        receiverId: widget.userId,
        content: messageText,
      );

      if (!result['success']) {
        if (mounted) {
          setState(() {
            _pendingMessages.remove(tempMessage);
            _isSending = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['error'] ?? 'Failed to send message')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingMessages.remove(tempMessage);
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted && _isSending) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _loadRecipientPhone() async {
    try {
      final recipient = await _authService.getUserById(widget.userId);
      if (!mounted) return;

      final phone = (recipient?.phone ?? '').trim();
      setState(() {
        _recipientPhone = phone.isNotEmpty ? phone : null;
        _isLoadingRecipientPhone = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recipientPhone = null;
        _isLoadingRecipientPhone = false;
      });
    }
  }

  Future<void> _callRecipient() async {
    if (_isLoadingRecipientPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading contact number...')),
      );
      return;
    }

    final phone = _recipientPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number is not available for this contact.'),
        ),
      );
      return;
    }

    final sanitizedPhone = _sanitizePhoneNumber(phone);
    if (sanitizedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number is not available for this contact.'),
        ),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        Uri(scheme: 'tel', path: sanitizedPhone),
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the phone app on this device.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start the call: $e')),
      );
    }
  }

  String _sanitizePhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      return '';
    }

    if (cleaned.startsWith('+')) {
      return '+${cleaned.substring(1).replaceAll('+', '')}';
    }

    return cleaned.replaceAll('+', '');
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: widget.userImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        widget.userImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Text(
                            widget.userName?.isNotEmpty == true
                                ? widget.userName![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Text(
                        widget.userName?.isNotEmpty == true
                            ? widget.userName![0].toUpperCase()
                            : '?',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.userName ?? 'User',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isLoadingRecipientPhone
                ? 'Loading phone number'
                : 'Call ${widget.userName ?? 'contact'}',
            icon: const Icon(Icons.phone_outlined),
            onPressed: _callRecipient,
          ),
        ],
      ),
      body: AppGradientBackground(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (_loadError != null &&
                          _messages.isEmpty &&
                          _pendingMessages.isEmpty)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: AppEmptyState(
                              icon: Icons.cloud_off_outlined,
                              title: 'Unable to load chat',
                              subtitle: _loadError?.contains('permission-denied') == true
                                  ? 'Permission denied by Firestore rules. Check your chat access.'
                                  : 'Firestore is offline or the conversation is not reachable right now.',
                              action: ElevatedButton.icon(
                                onPressed: _loadMessages,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ),
                          ),
                        )
                      : _messages.isEmpty && _pendingMessages.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: AppEmptyState(
                                  icon: Icons.chat_bubble_outline,
                                  title: 'No messages yet',
                                  subtitle: 'Start the conversation',
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  _messages.length + _pendingMessages.length,
                              itemBuilder: (context, index) {
                                final allMessages = [
                                  ..._messages,
                                  ..._pendingMessages
                                ];
                                final message = allMessages[index];
                                final isSent =
                                    message.senderId == currentUserId;

                                // Show date header if it's the first message or if the date changed
                                bool showDateHeader = false;
                                if (index == 0) {
                                  showDateHeader = true;
                                } else {
                                  final previousMessage =
                                      allMessages[index - 1];
                                  if (!_isSameDay(message.timestamp,
                                      previousMessage.timestamp)) {
                                    showDateHeader = true;
                                  }
                                }

                                //Logic to show time only for the last message in a minute-group from same sender
                                bool showTime = true;
                                if (index < allMessages.length - 1) {
                                  final nextMessage = allMessages[index + 1];
                                  if (nextMessage.senderId ==
                                          message.senderId &&
                                      _isSameMinute(message.timestamp,
                                          nextMessage.timestamp)) {
                                    showTime = false;
                                  }
                                }

                                final bubble = _MessageBubble(
                                  message: message,
                                  isSent: isSent,
                                  showTime: showTime,
                                  receiverImage: widget.userImage,
                                ).animate().fadeIn().slideX(
                                      begin: isSent ? 0.2 : -0.2,
                                      duration: 300.ms,
                                    );

                                if (showDateHeader) {
                                  return Column(
                                    children: [
                                      _DateHeader(date: message.timestamp),
                                      bubble,
                                    ],
                                  );
                                }

                                return bubble;
                              },
                            ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        cursorColor: colorScheme.primary,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        enabled: !_isSending,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 48,
                            height: 48,
                          ),
                          splashRadius: 24,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                          onPressed: _isSending ? null : _sendMessage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSent;
  final bool showTime;
  final String? receiverImage;

  const _MessageBubble({
    required this.message,
    required this.isSent,
    this.showTime = true,
    this.receiverImage,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isSent
        ? Theme.of(context).colorScheme.primary
        : Colors.white.withValues(alpha: 0.9);

    final isPending = message.id.startsWith('pending_');

    return Padding(
      padding: EdgeInsets.only(bottom: showTime ? 12 : 4),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            Opacity(
              opacity: showTime
                  ? 1.0
                  : 0.0, // Only show avatar for the last message in a group
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: receiverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          receiverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.14),
                            child: Text(
                              message.senderName.isNotEmpty
                                  ? message.senderName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12),
                            ),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.14),
                        child: Text(
                          message.senderName.isNotEmpty
                              ? message.senderName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft:
                          isSent ? const Radius.circular(20) : Radius.zero,
                      bottomRight:
                          isSent ? Radius.zero : const Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isSent ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (showTime) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isSent) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime); // e.g. 5:30 PM
  }
}

bool _isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

bool _isSameMinute(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day &&
      date1.hour == date2.hour &&
      date1.minute == date2.minute;
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    String formattedDate = _getFormattedDate(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          const Expanded(child: Divider(indent: 20, endIndent: 10)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.96)
                  : colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.95 : 0.8,
                ),
              ),
            ),
            child: Text(
              formattedDate,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider(indent: 10, endIndent: 20)),
        ],
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) return 'Today';
    if (dateToCheck == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }
}
