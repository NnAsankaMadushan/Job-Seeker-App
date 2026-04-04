import 'package:flutter/material.dart';
import 'package:job_seeker_app/l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/Screens/app_lock_screen.dart';
import 'package:job_seeker_app/Screens/forgot_password_screen.dart';
import 'package:job_seeker_app/Screens/Signup_screen.dart';
import 'package:job_seeker_app/Screens/register_screen.dart';
import 'package:job_seeker_app/models/user.dart' as app_user;
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

import '../widgets/social_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToAppLock() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppLockScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPill(
                  label: 'Job Seeker SL',
                  color: scheme.primary,
                ).animate().fadeIn(duration: 280.ms).slideY(begin: -0.08),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FeaturePill(
                      icon: Icons.lock_outline_rounded,
                      label: AppLocalizations.of(context)!.secureSignIn,
                    ),
                    _FeaturePill(
                      icon: Icons.flash_on_outlined,
                      label: AppLocalizations.of(context)!.fastHandoff,
                    ),
                    _FeaturePill(
                      icon: Icons.tips_and_updates_outlined,
                      label: AppLocalizations.of(context)!.smartAlerts,
                    ),
                  ],
                ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.06),
                const SizedBox(height: 28),
                AppGlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSectionHeader(
                          eyebrow: AppLocalizations.of(context)!.account,
                          title: AppLocalizations.of(context)!.welcomeBack,
                          subtitle: AppLocalizations.of(context)!.loginSubtitle,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.email,
                            hintText: 'name@example.com',
                            prefixIcon: const Icon(Icons.alternate_email_rounded),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context)!.emailError;
                            }
                            if (!value.contains('@')) {
                              return AppLocalizations.of(context)!.emailInvalid;
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ).animate().fadeIn(delay: 260.ms).slideX(begin: -0.04),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.password,
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.passwordError;
                            }
                            if (value.length < 8) {
                              return AppLocalizations.of(context)!
                                  .passwordLengthError;
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ).animate().fadeIn(delay: 340.ms).slideX(begin: -0.04),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                            child: Text(AppLocalizations.of(context)!.forgotPassword),
                          ),
                        ).animate().fadeIn(delay: 380.ms),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleLogin,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.arrow_forward_rounded),
                            label: Text(_isLoading
                                ? AppLocalizations.of(context)!.signingIn
                                : AppLocalizations.of(context)!.login),
                          ),
                        ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.06),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.center,
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.newHere,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupScreen(),
                                  ),
                                ),
                                child: Text(AppLocalizations.of(context)!
                                    .createAccount),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                        SocialLoginButtons(
                          isLoading: _isLoading,
                          onFacebookPressed: _handleFacebookSignIn,
                          onGooglePressed: _handleGoogleSignIn,
                          onApplePressed: () =>
                              _showProviderNotConfigured('Apple'),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.08),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authService = FirebaseAuthService();
    final result = await authService.login(
      email: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loginSuccessful)),
        );
      }
      _navigateToAppLock();
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.loginFailed}: ${result['message']}')),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) {
      return;
    }

    setState(() => _isLoading = true);

    final authService = FirebaseAuthService();
    final result = await authService.signInWithGoogle(
      forceAccountSelection: true,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in successful')),
      );
      _navigateAfterSocialAuth(result);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result['message']}')),
    );
  }

  Future<void> _handleFacebookSignIn() async {
    if (_isLoading) {
      return;
    }

    setState(() => _isLoading = true);

    final authService = FirebaseAuthService();
    final result = await authService.signInWithFacebook();

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facebook sign-in successful')),
      );
      _navigateAfterSocialAuth(result);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result['message']}')),
    );
  }

  void _showProviderNotConfigured(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider sign-in is not configured yet.')),
    );
  }

  void _navigateAfterSocialAuth(Map<String, dynamic> result) {
    final requiresProfileCompletion =
        result['requiresProfileCompletion'] == true;
    final user = result['user'] as app_user.User?;

    if (requiresProfileCompletion) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterScreen(
            email: user?.email ?? '',
            initialUser: user,
            isProfileSetupOnly: true,
          ),
        ),
        (route) => false,
      );
      return;
    }

    _navigateToAppLock();
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.06 : 0.4,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha:
                Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.54,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: scheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
