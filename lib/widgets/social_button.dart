import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SocialButton(
              icon: Icons.facebook,
              label: 'Facebook',
              color: const Color(0xFF1877F2),
              onPressed: () {},
            ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.3),
            _SocialButton(
              icon: Icons.g_mobiledata,
              label: 'Google',
              color: const Color(0xFFDB4437),
              onPressed: () {},
            ).animate().fadeIn(delay: 600.ms),
            _SocialButton(
              icon: Icons.apple,
              label: 'Apple',
              color: Colors.black,
              onPressed: () {},
            ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.3),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sign in with $label',
      child: Material(
        elevation: 2,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}