import 'package:flutter/material.dart';
import 'package:job_seeker_app/Screens/app_credential_setup_screen.dart';
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
  AppCredential? _appCredential;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final appLockEnabled = await _settingsService.isAppLockEnabled();
    final appCredential = await _settingsService.getAppCredential();

    if (!mounted) {
      return;
    }

    setState(() {
      _appLockEnabled = appLockEnabled;
      _appCredential = appCredential;
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

  Future<void> _openCredentialSetup() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AppCredentialSetupScreen()),
    );

    if (result == true) {
      await _loadSecuritySettings();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App lock credential saved')),
      );
    }
  }

  Future<void> _clearCredential() async {
    await _settingsService.clearAppCredential();
    if (!mounted) {
      return;
    }
    setState(() => _appCredential = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App PIN/password removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final credentialLabel = _appCredential == null
        ? 'Not set. Uses device biometrics/screen lock.'
        : _appCredential!.isPin
        ? 'PIN is configured for this app'
        : 'Password is configured for this app';

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
                        _appLockEnabled ? Icons.lock_outline : Icons.lock_open_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Enable app lock'),
                      subtitle: const Text('Require unlock when opening the app'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.pin_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(_appCredential == null ? 'Set app PIN or password' : 'Change app PIN or password'),
                      subtitle: Text(credentialLabel),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openCredentialSetup,
                    ),
                    if (_appCredential != null) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        title: const Text('Remove app PIN/password'),
                        subtitle: const Text('Revert to device biometrics/screen lock only'),
                        onTap: _clearCredential,
                      ),
                    ],
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.settings_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Open device app settings'),
                      subtitle: const Text('Manage permissions in system settings'),
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
