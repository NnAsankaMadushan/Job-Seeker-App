import 'package:flutter/material.dart';
import 'package:job_seeker_app/theme/theme_controller.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AppSectionHeader(
                title: 'Theme',
                subtitle: 'Choose how the app looks on this device',
              ),
              const SizedBox(height: 14),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.instance.themeMode,
                builder: (context, mode, _) {
                  return AppGlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _ThemeModeTile(
                          value: ThemeMode.light,
                          groupValue: mode,
                          icon: Icons.light_mode_outlined,
                          title: 'Light',
                          subtitle: 'Always use light mode',
                          onChanged: ThemeController.instance.setThemeMode,
                        ),
                        const Divider(height: 1),
                        _ThemeModeTile(
                          value: ThemeMode.dark,
                          groupValue: mode,
                          icon: Icons.dark_mode_outlined,
                          title: 'Dark',
                          subtitle: 'Always use dark mode',
                          onChanged: ThemeController.instance.setThemeMode,
                        ),
                        const Divider(height: 1),
                        _ThemeModeTile(
                          value: ThemeMode.system,
                          groupValue: mode,
                          icon: Icons.phone_android_outlined,
                          title: 'System',
                          subtitle: 'Match your device theme',
                          onChanged: ThemeController.instance.setThemeMode,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final ThemeMode value;
  final ThemeMode groupValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: value,
      groupValue: groupValue,
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
      secondary: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}
