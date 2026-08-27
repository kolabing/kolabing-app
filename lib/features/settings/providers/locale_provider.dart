import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/locale_service.dart';

/// Locale state. A null [locale] means "follow the system language".
class LocaleState {
  const LocaleState({this.locale, this.isLoading = true});

  /// The pinned app language, or null to follow the device language.
  final Locale? locale;
  final bool isLoading;

  LocaleState copyWith({
    Locale? locale,
    bool clearLocale = false,
    bool? isLoading,
  }) => LocaleState(
    locale: clearLocale ? null : (locale ?? this.locale),
    isLoading: isLoading ?? this.isLoading,
  );
}

/// Notifier for the app language preference, persisted via [LocaleService].
class LocaleNotifier extends Notifier<LocaleState> {
  late final LocaleService _service;

  @override
  LocaleState build() {
    _service = LocaleService.instance;
    Future.microtask(_loadLocale);
    return const LocaleState();
  }

  Future<void> _loadLocale() async {
    final saved = await _service.getLocale();
    state = state.copyWith(
      locale: saved,
      clearLocale: saved == null,
      isLoading: false,
    );
  }

  /// Pin the app to [locale], or pass null to follow the system language.
  Future<void> setLocale(Locale? locale) async {
    state = state.copyWith(locale: locale, clearLocale: locale == null);
    await _service.setLocale(locale);
  }
}

/// Provider for the app language preference.
final localeProvider = NotifierProvider<LocaleNotifier, LocaleState>(
  LocaleNotifier.new,
);
