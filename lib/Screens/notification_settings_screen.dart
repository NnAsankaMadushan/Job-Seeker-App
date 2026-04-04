import 'package:flutter/material.dart';
import 'package:job_seeker_app/services/app_settings_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final AppSettingsService _settingsService = AppSettingsService.instance;

  bool _isLoading = true;
  bool _isUpdatingPush = false;
  bool _pushNotificationsEnabled = true;
  bool _inAppNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pushEnabled = await _settingsService.isPushNotificationsEnabled();
    final inAppEnabled = await _settingsService.isInAppNotificationsEnabled();

    if (!mounted) {
      return;
    }

    setState(() {
      _pushNotificationsEnabled = pushEnabled;
      _inAppNotificationsEnabled = inAppEnabled;
      _isLoading = false;
    });
  }

  Future<void> _togglePushNotifications(bool enabled) async {
    if (_isUpdatingPush) {
      return;
    }

    setState(() => _isUpdatingPush = true);

    bool finalValue = enabled;
    if (enabled) {
      final status = await Permission.notification.request();
      finalValue = status.isGranted || status.isLimited || status.isProvisional;
    }

    await _settingsService.setPushNotificationsEnabled(finalValue);

    if (!mounted) {
      return;
    }

    setState(() {
      _pushNotificationsEnabled = finalValue;
      _isUpdatingPush = false;
    });

    if (enabled && !finalValue) {
      _showEnableNotificationsDialog();
    }
  }

  Future<void> _toggleInAppNotifications(bool enabled) async {
    await _settingsService.setInAppNotificationsEnabled(enabled);
    if (!mounted) {
      return;
    }
    setState(() => _inAppNotificationsEnabled = enabled);
  }

  void _showEnableNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
            'To receive push notifications, please enable them in your device settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              try {
                AppSettings.openAppSettings(type: AppSettingsType.notification);
              } catch (e) {
                // Ignore errors
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AppSectionHeader(
                title: 'Alerts',
                subtitle: 'Choose how you receive job and message updates',
              ),
              const SizedBox(height: 14),
              AppGlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: _pushNotificationsEnabled,
                      onChanged: _isUpdatingPush ? null : _togglePushNotifications,
                      secondary: Icon(
                        Icons.notifications_active_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Push notifications'),
                      subtitle: const Text('Allow system push notifications'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      value: _inAppNotificationsEnabled,
                      onChanged: _toggleInAppNotifications,
                      secondary: Icon(
                        Icons.mark_chat_unread_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('In-app notifications'),
                      subtitle: const Text('Show notification badges and inbox updates'),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
