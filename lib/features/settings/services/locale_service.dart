import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting the app's language preference.
///
/// A null [Locale] means "follow the system language" — the app does not pin a
/// language and [MaterialApp] resolves it against [supportedLocales].
class LocaleService {
  LocaleService._();
  static final LocaleService _instance = LocaleService._();
  static LocaleService get instance => _instance;

  static const String _localeKey = 'app_locale';

  /// Locales the app ships translations for. Order is the resolution
  /// preference when the device language is not an exact match.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ca'),
  ];

  /// Read the saved language code, or null to follow the system language.
  Future<Locale?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code == null || code.isEmpty) return null;
    final match = supportedLocales
        .where((l) => l.languageCode == code)
        .toList();
    return match.isEmpty ? null : match.first;
  }

  /// Persist the chosen language, or pass null to clear it (follow system).
  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }
}
