import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/Screens/Login_screen.dart';
import 'package:job_seeker_app/Screens/app_lock_screen.dart';
import 'package:job_seeker_app/Screens/register_screen.dart';
import 'package:job_seeker_app/models/user.dart' as app_user;
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

import '../widgets/social_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ).animate().fadeIn(duration: 240.ms),
                const SizedBox(height: 8),
                AppPill(
                  label: 'Create your hiring workspace',
                  icon: Icons.person_add_alt_1_rounded,
                  color: scheme.secondary,
                ).animate().fadeIn(delay: 60.ms).slideY(begin: -0.08),
                const SizedBox(height: 18),
                // Wrap(
                //   spacing: 10,
                //   runSpacing: 10,
                //   children: const [
                //     _StepPill(step: '01', label: 'Account setup'),
                //     _StepPill(step: '02', label: 'Profile details'),
                //     _StepPill(step: '03', label: 'Start exploring'),
                //   ],
                // ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.06),
                const SizedBox(height: 18),
                AppGlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(
                          eyebrow: 'Step 1',
                          title: 'Create your account',
                          subtitle:
                              'Use an email and password you will remember. You can add the rest of your information next.',
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'name@example.com',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.04),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: 'Create a secure password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 380.ms).slideX(begin: -0.04),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            hintText: 'Repeat your password',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 460.ms).slideX(begin: -0.04),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleSignup,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.arrow_forward_rounded),
                            label:
                                Text(_isLoading ? 'Preparing...' : 'Continue'),
                          ),
                        ).animate().fadeIn(delay: 540.ms).slideY(begin: 0.06),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.center,
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              Text(
                                'Already have an account?',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                ),
                                child: const Text('Log in'),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 620.ms),
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
                ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.08),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignup() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterScreen(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        ),
      );
    });
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

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppLockScreen()),
      (route) => false,
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.step,
    required this.label,
  });

  final String step;
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
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.14),
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
