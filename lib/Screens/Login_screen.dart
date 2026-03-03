import 'package:job_seeker_app/Screens/Signup_screen.dart';
import 'package:job_seeker_app/Screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';
import '../widgets/social_button.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              children: [
                Icon(
                  Icons.chat_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ).animate().shimmer().scale(
                      begin: const Offset(0.94, 0.94),
                      end: const Offset(1.06, 1.06),
                      duration: 1000.ms,
                    ),
                const SizedBox(height: 20),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ).animate().fadeIn().slideY(),
                const SizedBox(height: 8),
                Text(
                  'Log in to continue your job conversations.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                AppGlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters long';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ).animate().fadeIn().slideX(),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters long';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ).animate().fadeIn(delay: 160.ms).slideX(),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Login'),
                          ),
                        ).animate().fadeIn(delay: 280.ms).slideY(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?"),
                            TextButton(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              ),
                              child: const Text('Sign Up'),
                            ),
                          ],
                        ).animate().fadeIn(delay: 360.ms),
                        SocialLoginButtons(
                          isLoading: _isLoading,
                          onGooglePressed: _handleGoogleSignIn,
                          onApplePressed: () =>
                              _showProviderNotConfigured('Apple'),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.08),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Use Firebase Authentication
      final authService = FirebaseAuthService();
      final result = await authService.login(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );

          _navigateToHome();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${result['message']}')),
          );
        }
      }
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

      _navigateToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result['message']}')),
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
  //     _navigateToHome();
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
