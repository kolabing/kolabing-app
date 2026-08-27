import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/theme_service.dart';

/// Theme state
class ThemeState {
  const ThemeState({this.themeMode = ThemeMode.light, this.isLoading = true});

  final ThemeMode themeMode;
  final bool isLoading;

  ThemeState copyWith({ThemeMode? themeMode, bool? isLoading}) => ThemeState(
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
    // Dark mode is temporarily disabled — always force light mode.
    state = state.copyWith(themeMode: ThemeMode.light, isLoading: false);
  }

  /// Set theme mode and persist (dark mode temporarily disabled)
  Future<void> setThemeMode(ThemeMode mode) async {
    // No-op until dark mode is re-enabled.
  }

  /// Toggle between light and dark (dark mode temporarily disabled)
  Future<void> toggleTheme() async {
    // No-op until dark mode is re-enabled.
  }
}

/// Provider for theme state
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);
