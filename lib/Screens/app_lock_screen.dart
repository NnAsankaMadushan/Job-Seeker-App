import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_seeker_app/Screens/Login_screen.dart';
import 'package:job_seeker_app/Screens/home_page.dart';
import 'package:job_seeker_app/Screens/register_screen.dart';
import 'package:job_seeker_app/models/user.dart' as app_user;
import 'package:job_seeker_app/services/app_settings_service.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

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

    final currentUserDataFuture = authService.getCurrentUserData();
    final requiresProfileCompletionFuture =
        authService.requiresProfileCompletion();
    final appSettings = AppSettingsService.instance;
    final shouldSkipAppLockOnceFuture = appSettings.shouldSkipAppLockOnce();
    final appLockEnabledFuture = appSettings.isAppLockEnabled();

    try {
      final currentUserData = await currentUserDataFuture;
      if (!mounted) return;

      final requiresProfileCompletion = await requiresProfileCompletionFuture;

      if (!mounted) return;

      if (requiresProfileCompletion) {
        _navigateToProfileSetup(currentUserData);
        return;
      }

      final shouldSkipAppLockOnce = await shouldSkipAppLockOnceFuture;

      if (!mounted) return;

      if (shouldSkipAppLockOnce) {
        await appSettings.setSkipAppLockOnce(false);
        _navigateToHome();
        return;
      }

      final appLockEnabled = await appLockEnabledFuture;

      if (!mounted) return;

      if (!appLockEnabled) {
        _navigateToHome();
        return;
      }

      final isDeviceSupported = await _localAuthentication.isDeviceSupported();
      final availableBiometrics =
          await _localAuthentication.getAvailableBiometrics();
      final availableMethods = _resolveAvailableMethods(
        availableBiometrics,
        isDeviceSupported: isDeviceSupported,
      );
      final canUseDeviceAuth =
          isDeviceSupported || availableBiometrics.isNotEmpty;

      if (!mounted) return;

      setState(() {
        _canUseDeviceAuth = canUseDeviceAuth;
        _availableBiometrics = availableBiometrics;
        _preferredBiometric = _resolvePreferredBiometric(availableBiometrics);
        _availableMethods = availableMethods;
        _statusMessage = canUseDeviceAuth
            ? availableMethods.length == 1 &&
                    availableMethods.first == 'PIN / Pattern / Password'
                ? 'This device face unlock is not available to apps. Use PIN / Pattern / Password.'
                : availableMethods.isEmpty
                    ? 'Use your device screen lock to continue.'
                    : 'Use ${availableMethods.join(' / ')} to continue.'
            : 'Set up a screen lock on this device to unlock the app.';
      });

      if (!canUseDeviceAuth) {
        return;
      }

      await _authenticate();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = _resolveAuthErrorMessage(e);
      });
    }
  }

  BiometricType? _resolvePreferredBiometric(
      List<BiometricType> availableBiometrics) {
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
    final hasFingerprint =
        availableBiometrics.contains(BiometricType.fingerprint);
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
        return 'Set up a PIN, pattern, or password on this device and try again.';
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
      _statusMessage = 'Verification canceled. Tap retry to try again.';
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  void _navigateToProfileSetup(app_user.User? user) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          email: user?.email ?? '',
          initialUser: user,
          isProfileSetupOnly: true,
        ),
      ),
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
      body: AppGradientBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppGlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.14),
                      ),
                      child: Icon(
                        _getAuthIcon(),
                        size: 42,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Secure Unlock',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_availableMethods.isNotEmpty)
                      Text(
                        'Available: ${_availableMethods.join(' | ')}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: _isAuthenticating
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed:
                                  _canUseDeviceAuth ? _authenticate : null,
                              icon: const Icon(Icons.lock_open_rounded),
                              label: const Text('Retry device unlock'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
