import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/models/notification.dart';
import 'package:job_seeker_app/services/firebase_notification_service.dart';
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
        return Icons.work_outline_rounded;
      case 'message':
        return Icons.forum_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'system':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(BuildContext context, String type) {
    switch (type) {
      case 'job':
      case 'application':
        return Theme.of(context).colorScheme.primary;
      case 'message':
        return Theme.of(context).colorScheme.secondary;
      case 'payment':
        return const Color(0xFF059669);
      case 'system':
        return Theme.of(context).colorScheme.tertiary;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
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
              final messenger = ScaffoldMessenger.of(context);
              await _notificationService.markAllAsRead();
              if (!mounted) {
                return;
              }
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                ),
              );
            },
            child: const Text('Mark all read'),
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
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load notifications',
                    subtitle: '${snapshot.error}',
                  ),
                ),
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
                    subtitle: 'You are all caught up right now.',
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
              children: [
                const AppSectionHeader(
                  eyebrow: 'Inbox',
                  title: 'Everything that needs your attention',
                  subtitle: 'Swipe any card away when you no longer need it.',
                ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.08),
                const SizedBox(height: 18),
                for (var index = 0; index < notifications.length; index++) ...[
                  _NotificationCard(
                    notification: notifications[index],
                    color: _getNotificationColor(
                        context, notifications[index].type),
                    icon: _getNotificationIcon(notifications[index].type),
                    onTap: () async {
                      if (!notifications[index].isRead) {
                        await _notificationService.markAsRead(
                          notifications[index].id,
                        );
                      }
                    },
                    onDismissed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await _notificationService.deleteNotification(
                        notifications[index].id,
                      );
                      if (!mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Notification removed')),
                      );
                    },
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 120 + (index * 70)))
                      .slideX(begin: 0.05),
                  if (index != notifications.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.onDismissed,
  });

  final AppNotification notification;
  final Color color;
  final IconData icon;
  final Future<void> Function() onTap;
  final Future<void> Function() onDismissed;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFFEF4444),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: AppGlassCard(
        onTap: () => onTap(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDecoratedIcon(
              icon: icon,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
              size: 54,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.w700
                                        : FontWeight.w800,
                                  ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(left: 12, top: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  AppPill(
                    label: notification.getTimeAgo(),
                    icon: Icons.schedule_rounded,
                    color: color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
