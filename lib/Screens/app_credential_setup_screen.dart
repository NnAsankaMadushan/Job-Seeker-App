import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_seeker_app/services/app_settings_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

class AppCredentialSetupScreen extends StatefulWidget {
  const AppCredentialSetupScreen({super.key});

  @override
  State<AppCredentialSetupScreen> createState() => _AppCredentialSetupScreenState();
}

class _AppCredentialSetupScreenState extends State<AppCredentialSetupScreen> {
  final TextEditingController _secretController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isPin = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _secretController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateInputs() {
    final secret = _secretController.text.trim();
    final confirm = _confirmController.text.trim();

    if (secret.isEmpty || confirm.isEmpty) {
      return 'Enter and confirm your credential.';
    }

    if (secret != confirm) {
      return 'Values do not match.';
    }

    if (_isPin) {
      if (!RegExp(r'^\d+$').hasMatch(secret)) {
        return 'PIN must contain only digits.';
      }
      if (secret.length < 4 || secret.length > 6) {
        return 'PIN must be between 4 and 6 digits.';
      }
    } else {
      if (secret.length < 6) {
        return 'Password must be at least 6 characters.';
      }
    }

    return null;
  }

  Future<void> _saveCredential() async {
    final error = _validateInputs();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _isSaving = true);

    final secret = _secretController.text.trim();
    await AppSettingsService.instance.saveAppCredential(
      secret: secret,
      isPin: _isPin,
    );
    await AppSettingsService.instance.setAppLockEnabled(true);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final secretLabel = _isPin ? 'PIN' : 'Password';
    return Scaffold(
      appBar: AppBar(
        title: const Text('App PIN / Password'),
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AppSectionHeader(
                title: 'App Lock Credential',
                subtitle: 'Set a PIN or password used only to unlock this app',
              ),
              const SizedBox(height: 14),
              AppGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('PIN'),
                          icon: Icon(Icons.pin_outlined),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Password'),
                          icon: Icon(Icons.password_outlined),
                        ),
                      ],
                      selected: {_isPin},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _isPin = selection.first;
                          _secretController.clear();
                          _confirmController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _secretController,
                      obscureText: true,
                      keyboardType: _isPin ? TextInputType.number : TextInputType.visiblePassword,
                      inputFormatters: _isPin
                          ? [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ]
                          : null,
                      decoration: InputDecoration(
                        labelText: 'New $secretLabel',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmController,
                      obscureText: true,
                      keyboardType: _isPin ? TextInputType.number : TextInputType.visiblePassword,
                      inputFormatters: _isPin
                          ? [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ]
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Confirm $secretLabel',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveCredential,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(_isSaving ? 'Saving...' : 'Save'),
                      ),
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
