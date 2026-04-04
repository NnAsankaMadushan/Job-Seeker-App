import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';
import 'package:job_seeker_app/Screens/reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String otp;
  final void Function(BuildContext)? onVerified;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.otp,
    this.onVerified,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_otpController.text.trim() == widget.otp) {
      if (widget.onVerified != null) {
        widget.onVerified!(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: widget.email),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPill(
                  label: 'Security',
                  color: scheme.primary,
                ).animate().fadeIn(duration: 280.ms).slideY(begin: -0.08),
                const SizedBox(height: 28),
                AppGlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(
                          eyebrow: 'OTP Verification',
                          title: 'Enter OTP',
                          subtitle: 'Please enter the 6-digit OTP sent to your email address.',
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _otpController,
                          decoration: const InputDecoration(
                            labelText: 'OTP',
                            hintText: 'Enter 6-digit code',
                            prefixIcon: Icon(Icons.security_rounded),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the OTP';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 260.ms).slideX(begin: -0.04),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _verifyOtp,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Verify OTP'),
                          ),
                        ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.06),
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
}
