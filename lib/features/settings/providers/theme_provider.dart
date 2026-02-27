import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/theme_service.dart';

/// Theme state
class ThemeState {
  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.isLoading = true,
  });

  final ThemeMode themeMode;
  final bool isLoading;

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isLoading,
  }) =>
      ThemeState(
        themeMode: themeMode ?? this.themeMode,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Theme notifier for managing app theme
class ThemeNotifier extends Notifier<ThemeState> {
  late final ThemeService _service;

  @override
  ThemeState build() {
    _service = ThemeService.instance;
    // Load saved theme on initialization
    Future.microtask(() => _loadTheme());
    return const ThemeState();
  }

  Future<void> _loadTheme() async {
    final savedMode = await _service.getThemeMode();
    state = state.copyWith(
      themeMode: savedMode,
      isLoading: false,
    );
  }

  /// Set theme mode and persist
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _service.setThemeMode(mode);
  }

  /// Toggle between light and dark (ignoring system)
  Future<void> toggleTheme() async {
    final newMode =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }
}

/// Provider for theme state
final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
