import 'package:flutter/material.dart';
import 'package:job_seeker_app/services/app_settings_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final AppSettingsService _settingsService = AppSettingsService.instance;

  bool _isLoading = true;
  bool _isUpdatingPush = false;
  bool _isOpeningSystemSettings = false;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission is blocked. Enable it in device settings.'),
        ),
      );
    }
  }

  Future<void> _toggleInAppNotifications(bool enabled) async {
    await _settingsService.setInAppNotificationsEnabled(enabled);
    if (!mounted) {
      return;
    }
    setState(() => _inAppNotificationsEnabled = enabled);
  }

  Future<void> _openSystemNotificationSettings() async {
    if (_isOpeningSystemSettings) {
      return;
    }

    setState(() => _isOpeningSystemSettings = true);
    final opened = await openAppSettings();

    if (!mounted) {
      return;
    }

    setState(() => _isOpeningSystemSettings = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'System settings opened'
              : 'Could not open system settings on this device',
        ),
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
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.settings_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Open system notification settings'),
                      subtitle: const Text('Manage notification permission on your phone'),
                      trailing: _isOpeningSystemSettings
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _isOpeningSystemSettings ? null : _openSystemNotificationSettings,
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
