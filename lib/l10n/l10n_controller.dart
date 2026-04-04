import 'package:flutter/material.dart';

class L10nController {
  L10nController._();

  static final L10nController instance = L10nController._();

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  void setLocale(Locale newLocale) {
    if (locale.value == newLocale) {
      return;
    }
    locale.value = newLocale;
  }
}
