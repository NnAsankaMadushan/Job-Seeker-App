import 'package:job_seeker_app/Screens/Login_screen.dart';
import 'package:job_seeker_app/Screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/Screens/home_page.dart';
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
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 68,
                  color: Theme.of(context).colorScheme.primary,
                ).animate().shimmer(),
                const SizedBox(height: 24),
                AppGlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 120.ms).slideX(),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 220.ms).slideX(),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock_clock_outlined),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 320.ms).slideX(),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Continue'),
                          ),
                        ).animate().fadeIn(delay: 420.ms).slideY(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?'),
                            TextButton(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              ),
                              child: const Text('Log in'),
                            ),
                          ],
                        ).animate().fadeIn(delay: 500.ms),
                        SocialLoginButtons(
                          isLoading: _isLoading,
                          onGooglePressed: _handleGoogleSignIn,
                          onApplePressed: () => _showProviderNotConfigured('Apple'),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.08),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignup() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // Simulate API call delay
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);
        // Navigate to RegisterScreen with email and password
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterScreen(
              email: _emailController.text,
              password: _passwordController.text,
            ),
          ),
        );
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final authService = FirebaseAuthService();
    final result = await authService.signInWithGoogle(
      forceAccountSelection: true,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in successful!')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${result['message']}')),
      );
    }
  }

  // Future<void> _handleFacebookSignIn() async {
  //   if (_isLoading) return;
  //
  //   setState(() => _isLoading = true);
  //
  //   final authService = FirebaseAuthService();
  //   final result = await authService.signInWithFacebook();
  //
  //   if (!mounted) return;
  //
  //   setState(() => _isLoading = false);
  //
  //   if (result['success']) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Facebook sign-in successful!')),
  //     );
  //
  //     Navigator.pushAndRemoveUntil(
  //       context,
  //       MaterialPageRoute(builder: (_) => const HomePage()),
  //       (route) => false,
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Facebook sign-in failed: ${result['message']}')),
  //     );
  //   }
  // }

  void _showProviderNotConfigured(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider sign-in is not configured yet.')),
    );
  }
}
