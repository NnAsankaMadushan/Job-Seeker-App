import 'package:flutter/material.dart';

class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  void setThemeMode(ThemeMode mode) {
    if (themeMode.value == mode) {
      return;
    }
    themeMode.value = mode;
  }
}
