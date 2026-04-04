import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/Screens/Login_screen.dart';
import 'package:job_seeker_app/Screens/appearance_screen.dart';
import 'package:job_seeker_app/Screens/notification_settings_screen.dart';
import 'package:job_seeker_app/Screens/privacy_security_screen.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';
import 'package:job_seeker_app/l10n/l10n_controller.dart';
import 'package:job_seeker_app/l10n/app_localizations.dart';

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
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.logout),
          content: Text(l10n.logoutMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.logout),
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

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.logoutFailed}: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              AppGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppPill(
                      label: 'Workspace controls',
                      icon: Icons.tune_rounded,
                      color: scheme.primary,
                    ),
                    // const SizedBox(height: 16),
                    // Text(
                    //   'Keep notifications, privacy, and appearance in sync with how you work.',
                    //   style:
                    //       Theme.of(context).textTheme.headlineSmall?.copyWith(
                    //             fontWeight: FontWeight.w800,
                    //           ),
                    // ),
                    // const SizedBox(height: 10),
                    // Text(
                    //   'These settings shape how the app looks, how it protects your account, and how it gets your attention.',
                    //   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    //         color: scheme.onSurfaceVariant,
                    //       ),
                    // ),
                  ],
                ),
              ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.08),
              const SizedBox(height: 24),
              const AppSectionHeader(
                eyebrow: 'Preferences',
                title: 'Personalize the app',
                subtitle: 'Update the parts of the experience you notice most.',
              ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08),
              const SizedBox(height: 16),
              AppListTileCard(
                onTap: _openNotifications,
                leading: AppDecoratedIcon(
                  icon: Icons.notifications_active_outlined,
                  color: scheme.primary,
                  backgroundColor: scheme.primary.withValues(alpha: 0.14),
                ),
                title: Text(
                  AppLocalizations.of(context)!.notifications,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.notificationsSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 160.ms).slideX(begin: 0.05),
              const SizedBox(height: 12),
              AppListTileCard(
                onTap: _openPrivacySecurity,
                leading: AppDecoratedIcon(
                  icon: Icons.verified_user_outlined,
                  color: scheme.secondary,
                  backgroundColor: scheme.secondary.withValues(alpha: 0.14),
                ),
                title: Text(
                  AppLocalizations.of(context)!.privacySecurity,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.privacySecuritySubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 240.ms).slideX(begin: 0.05),
              const SizedBox(height: 12),
              AppListTileCard(
                onTap: _openAppearance,
                leading: AppDecoratedIcon(
                  icon: Icons.palette_outlined,
                  color: scheme.tertiary,
                  backgroundColor: scheme.tertiary.withValues(alpha: 0.14),
                ),
                title: Text(
                  AppLocalizations.of(context)!.appearance,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.appearanceSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 320.ms).slideX(begin: 0.05),
              const SizedBox(height: 12),
              AppListTileCard(
                onTap: () => _showLanguagePicker(context),
                leading: AppDecoratedIcon(
                  icon: Icons.language_rounded,
                  color: Colors.blue,
                  backgroundColor: Colors.blue.withValues(alpha: 0.14),
                ),
                title: Text(
                  AppLocalizations.of(context)!.language,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                subtitle: ValueListenableBuilder<Locale>(
                  valueListenable: L10nController.instance.locale,
                  builder: (context, locale, _) {
                    String langName = 'English';
                    if (locale.languageCode == 'si') langName = 'සිංහල';
                    if (locale.languageCode == 'ta') langName = 'தமிழ்';
                    return Text(
                      langName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    );
                  },
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 360.ms).slideX(begin: 0.05),
              const SizedBox(height: 24),
              AppSectionHeader(
                eyebrow: AppLocalizations.of(context)!.account,
                title: AppLocalizations.of(context)!.sessionControls,
                subtitle: AppLocalizations.of(context)!.sessionSubtitle,
              ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.08),
              const SizedBox(height: 16),
              AppGlassCard(
                onTap: _isLoggingOut ? null : _handleLogout,
                child: Row(
                  children: [
                    AppDecoratedIcon(
                      icon: Icons.logout_rounded,
                      color: const Color(0xFFEF4444),
                      backgroundColor:
                          const Color(0xFFEF4444).withValues(alpha: 0.14),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.logout,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppLocalizations.of(context)!.logoutSubtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _isLoggingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                  ],
                ),
              ).animate().fadeIn(delay: 440.ms).slideY(begin: 0.08),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AppGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.selectLanguage,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListTile(
                title: Text(l10n.english),
                onTap: () {
                  L10nController.instance.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(l10n.sinhala),
                onTap: () {
                  L10nController.instance.setLocale(const Locale('si'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(l10n.tamil),
                onTap: () {
                  L10nController.instance.setLocale(const Locale('ta'));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
