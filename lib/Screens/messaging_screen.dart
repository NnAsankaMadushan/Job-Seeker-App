import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/models/message.dart';
import 'package:job_seeker_app/services/firebase_chat_service.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';
import 'package:intl/intl.dart';

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

class _MessagingScreenState extends State<MessagingScreen> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<List<Message>>? _messagesSubscription;
  List<Message> _messages = [];
  List<Message> _pendingMessages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _userIsAtBottom = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
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
    setState(() => _isLoading = true);

    try {
      await _messagesSubscription?.cancel();

      // Listen to messages stream
      _messagesSubscription =
          FirebaseChatService().getMessages(widget.userId).listen((messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            // Remove pending messages that have now been delivered (matching by content and sender)
            _pendingMessages.removeWhere((pending) => 
              messages.any((m) => m.content == pending.content && m.senderId == pending.senderId));
            _isLoading = false;
          });

          // Mark messages as read whenever messages update
          FirebaseChatService().markAsRead(widget.userId);

          // Auto-scroll to bottom only if user is already at the bottom OR it's the very first load
          if (_isLoading || _userIsAtBottom) {
            _scrollToBottom();
          }
          
          setState(() {
            _isLoading = false;
          });
        }
      });

      // Mark messages as read immediately when screen opens
      await FirebaseChatService().markAsRead(widget.userId);
    } catch (e) {
      setState(() => _isLoading = false);
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
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Failed to send message')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingMessages.remove(tempMessage);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
    final currentUserId = FirebaseAuthService().currentUser?.uid ?? '';

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
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: widget.userImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        widget.userImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Text(
                            widget.userName?.isNotEmpty == true ? widget.userName![0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Text(
                        widget.userName?.isNotEmpty == true ? widget.userName![0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: AppGradientBackground(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
                          itemCount: _messages.length + _pendingMessages.length,
                          itemBuilder: (context, index) {
                            final allMessages = [..._messages, ..._pendingMessages];
                            final message = allMessages[index];
                            final isSent = message.senderId == currentUserId;

                            // Show date header if it's the first message or if the date changed
                            bool showDateHeader = false;
                            if (index == 0) {
                              showDateHeader = true;
                            } else {
                              final previousMessage = allMessages[index - 1];
                              if (!_isSameDay(message.timestamp, previousMessage.timestamp)) {
                                showDateHeader = true;
                              }
                            }

                            //Logic to show time only for the last message in a minute-group from same sender
                            bool showTime = true;
                            if (index < allMessages.length - 1) {
                              final nextMessage = allMessages[index + 1];
                              if (nextMessage.senderId == message.senderId &&
                                  _isSameMinute(message.timestamp, nextMessage.timestamp)) {
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
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
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
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
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
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                        onPressed: _isSending ? null : _sendMessage,
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
        : Colors.white.withOpacity(0.9);
    
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
              opacity: showTime ? 1.0 : 0.0, // Only show avatar for the last message in a group
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: receiverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          receiverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.14),
                            child: Text(
                              message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12),
                            ),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.14),
                        child: Text(
                          message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12),
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
    String formattedDate = _getFormattedDate(date);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          const Expanded(child: Divider(indent: 20, endIndent: 10)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Text(
              formattedDate,
              style: TextStyle(
                color: Colors.grey[600],
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
