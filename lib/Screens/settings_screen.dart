import 'package:flutter/material.dart';
import 'package:job_seeker_app/Screens/appearance_screen.dart';
import 'package:job_seeker_app/Screens/Login_screen.dart';
import 'package:job_seeker_app/Screens/notification_settings_screen.dart';
import 'package:job_seeker_app/Screens/privacy_security_screen.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggingOut = false;

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
    );
  }

  void _openPrivacySecurity() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
    );
  }

  void _openAppearance() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AppearanceScreen()),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    setState(() => _isLoggingOut = true);

    try {
      await FirebaseAuthService().logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AppSectionHeader(
                title: 'Preferences',
                subtitle: 'Control your account and app behavior',
              ),
              const SizedBox(height: 14),
              AppGlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.notifications_active_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Notifications'),
                      subtitle: const Text('Manage push and in-app alerts'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openNotifications,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.security_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Privacy & Security'),
                      subtitle: const Text('Update lock and account access settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openPrivacySecurity,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.palette_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Appearance'),
                      subtitle: const Text('Customize visual preferences'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openAppearance,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppGlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text('Logout'),
                  subtitle: const Text('Sign out from your account'),
                  trailing: _isLoggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _isLoggingOut ? null : _handleLogout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
