import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/services/firebase_notification_service.dart';
import 'package:job_seeker_app/models/notification.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseNotificationService _notificationService =
      FirebaseNotificationService();

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'job':
      case 'application':
        return Icons.work_outline;
      case 'message':
        return Icons.message_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'job':
      case 'application':
        return Theme.of(context).colorScheme.primary;
      case 'message':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'system':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await _notificationService.markAllAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('All notifications marked as read')),
                );
              }
            },
            child: Text(
              'Mark all as read',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
            ),
          ),
        ],
      ),
      body: AppGradientBackground(
        child: StreamBuilder<List<AppNotification>>(
          stream: _notificationService.getNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: AppEmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'No notifications yet',
                    subtitle: 'You are all caught up right now',
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final color = _getNotificationColor(notification.type);

                return Dismissible(
                  key: Key(notification.id),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    await _notificationService
                        .deleteNotification(notification.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification removed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: notification.isRead ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () async {
                        if (!notification.isRead) {
                          await _notificationService
                              .markAsRead(notification.id);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: notification.isRead
                              ? Colors.transparent
                              : color.withOpacity(0.05),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.2),
                            child: Icon(
                              _getNotificationIcon(notification.type),
                              color: color,
                            ),
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(notification.message),
                              const SizedBox(height: 4),
                              Text(
                                notification.getTimeAgo(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: !notification.isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn().slideX();
              },
            );
          },
        ),
      ),
    );
  }
}
