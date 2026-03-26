import 'package:flutter/material.dart';
import 'package:job_seeker_app/services/app_settings_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';
import 'package:permission_handler/permission_handler.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final AppSettingsService _settingsService = AppSettingsService.instance;

  bool _isLoading = true;
  bool _isOpeningSettings = false;
  bool _isUpdatingLock = false;
  bool _appLockEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final appLockEnabled = await _settingsService.isAppLockEnabled();

    if (!mounted) {
      return;
    }

    setState(() {
      _appLockEnabled = appLockEnabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleAppLock(bool enabled) async {
    if (_isUpdatingLock) {
      return;
    }
    setState(() => _isUpdatingLock = true);

    await _settingsService.setAppLockEnabled(enabled);

    if (!mounted) {
      return;
    }

    setState(() {
      _appLockEnabled = enabled;
      _isUpdatingLock = false;
    });
  }

  Future<void> _openDeviceSettings() async {
    if (_isOpeningSettings) {
      return;
    }

    setState(() => _isOpeningSettings = true);

    final didOpen = await openAppSettings();

    if (!mounted) {
      return;
    }

    setState(() => _isOpeningSettings = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          didOpen
              ? 'Device settings opened'
              : 'Could not open settings on this device',
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
        title: const Text('Privacy & Security'),
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AppSectionHeader(
                title: 'Security',
                subtitle: 'Manage app lock and permission access',
              ),
              const SizedBox(height: 14),
              AppGlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: _appLockEnabled,
                      onChanged: _isUpdatingLock ? null : _toggleAppLock,
                      secondary: Icon(
                        _appLockEnabled
                            ? Icons.lock_outline
                            : Icons.lock_open_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Enable app lock'),
                      subtitle: const Text(
                        'Require your device screen lock when opening the app',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.fingerprint_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Device screen lock'),
                      subtitle: const Text(
                        'Uses your phone PIN, pattern, password, face, or fingerprint automatically.',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.settings_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Open device app settings'),
                      subtitle:
                          const Text('Manage permissions in system settings'),
                      trailing: _isOpeningSettings
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _isOpeningSettings ? null : _openDeviceSettings,
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
