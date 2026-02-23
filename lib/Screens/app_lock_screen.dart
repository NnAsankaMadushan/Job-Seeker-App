import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:job_seeker_app/Screens/Login_screen.dart';
import 'package:job_seeker_app/Screens/home_page.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  bool _canUseDeviceAuth = false;
  bool _isAuthenticating = false;
  String _statusMessage = 'Preparing secure unlock...';
  BiometricType? _preferredBiometric;
  List<BiometricType> _availableBiometrics = const [];
  List<String> _availableMethods = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAndAuthenticate();
    });
  }

  Future<void> _setupAndAuthenticate() async {
    final authService = FirebaseAuthService();
    if (authService.currentUser == null) {
      _navigateToLogin();
      return;
    }

    try {
      final isDeviceSupported = await _localAuthentication.isDeviceSupported();
      final availableBiometrics = await _localAuthentication.getAvailableBiometrics();

      if (!mounted) return;

      if (!isDeviceSupported && availableBiometrics.isEmpty) {
        _navigateToHome();
        return;
      }

      final availableMethods = _resolveAvailableMethods(
        availableBiometrics,
        isDeviceSupported: isDeviceSupported,
      );

      setState(() {
        _canUseDeviceAuth = isDeviceSupported || availableBiometrics.isNotEmpty;
        _availableBiometrics = availableBiometrics;
        _preferredBiometric = _resolvePreferredBiometric(availableBiometrics);
        _availableMethods = availableMethods;
        _statusMessage = availableMethods.length == 1 &&
                availableMethods.first == 'PIN / Pattern / Password'
            ? 'This device face unlock is not available to apps. Use PIN / Pattern / Password.'
            : availableMethods.isEmpty
            ? 'Use your screen lock to continue'
            : 'Use ${availableMethods.join(' / ')} to continue';
      });

      await _authenticate();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = _resolveAuthErrorMessage(e);
      });
    }
  }

  BiometricType? _resolvePreferredBiometric(List<BiometricType> availableBiometrics) {
    if (availableBiometrics.contains(BiometricType.face)) {
      return BiometricType.face;
    }
    if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    }
    if (availableBiometrics.contains(BiometricType.strong)) {
      return BiometricType.strong;
    }
    if (availableBiometrics.contains(BiometricType.weak)) {
      return BiometricType.weak;
    }
    if (availableBiometrics.isNotEmpty) {
      return availableBiometrics.first;
    }
    return null;
  }

  List<String> _resolveAvailableMethods(
    List<BiometricType> availableBiometrics, {
    required bool isDeviceSupported,
  }) {
    final methods = <String>[];
    final hasFace = availableBiometrics.contains(BiometricType.face);
    final hasFingerprint = availableBiometrics.contains(BiometricType.fingerprint);
    final hasStrong = availableBiometrics.contains(BiometricType.strong);
    final hasWeak = availableBiometrics.contains(BiometricType.weak);

    if (hasFace) {
      methods.add('Face');
    }
    if (hasFingerprint) {
      methods.add('Fingerprint');
    }

    if (!hasFace && !hasFingerprint && (hasStrong || hasWeak)) {
      methods.add('Biometric');
    }

    if (isDeviceSupported) {
      methods.add('PIN / Pattern / Password');
    }
    return methods;
  }

  String _getAuthMethodLabel() {
    if (_availableMethods.isEmpty) {
      return 'your screen lock';
    }
    return _availableMethods.join(' / ');
  }

  IconData _getAuthIcon() {
    if (_availableBiometrics.contains(BiometricType.face) &&
        _availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.shield_outlined;
    }
    if (_preferredBiometric == BiometricType.face) {
      return Icons.face_retouching_natural;
    }
    if (_preferredBiometric == BiometricType.fingerprint) {
      return Icons.fingerprint;
    }
    if (_preferredBiometric == BiometricType.strong ||
        _preferredBiometric == BiometricType.weak) {
      return Icons.shield_outlined;
    }
    return Icons.lock_outline;
  }

  String _resolveAuthErrorMessage(PlatformException error) {
    switch (error.code) {
      case auth_error.notAvailable:
        return 'This device does not support secure app lock.';
      case auth_error.notEnrolled:
        return 'Set up face or fingerprint in device settings and try again.';
      case auth_error.passcodeNotSet:
        return 'Set up your PIN, pattern, or password in device settings.';
      case auth_error.lockedOut:
      case auth_error.permanentlyLockedOut:
        return 'Too many failed attempts. Use device credentials to unlock.';
      default:
        return error.message ?? 'Verification failed. Please try again.';
    }
  }

  Future<void> _authenticate() async {
    if (!_canUseDeviceAuth || _isAuthenticating) return;

    bool authenticated = false;

    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Waiting for verification...';
    });

    try {
      authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Unlock the app',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Authentication required',
            biometricHint: 'Use face, fingerprint, or screen lock',
            deviceCredentialsRequiredTitle: 'Screen lock required',
            deviceCredentialsSetupDescription:
                'Set a PIN, pattern, or password in your device settings.',
            cancelButton: 'Cancel',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancel',
          ),
        ],
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = _resolveAuthErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }

    if (!mounted) return;

    if (authenticated) {
      _navigateToHome();
      return;
    }

    setState(() {
      _statusMessage = 'Verification canceled. Tap "Unlock Now" to try again.';
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getAuthIcon(),
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'App Lock',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_availableMethods.isNotEmpty)
                    Text(
                      'Available: ${_availableMethods.join('  |  ')}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  const SizedBox(height: 24),
                  if (_isAuthenticating)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Unlock Now'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
