import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider definition that gives the rest of the application access to the ThemeNotifier.
/// Why: Allows UI widgets to watch theme changes and rebuild cleanly.
final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

/// Purpose:
/// Manages the application theme mode (Dark, Light, or System).
///
/// Task:
/// 1. Stores whether the app is currently in Light or Dark mode.
/// 2. Allows toggling between themes with zero UI lag.
/// 3. Prevents duplicate rebuilds when setting the same theme mode.
class ThemeNotifier extends Notifier<ThemeMode> {
  /// Sets the starting theme when the app launches.
  /// How: Defaults to system theme mode.
  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  /// Switches smoothly between Dark and Light mode.
  /// How: If currently Dark, switches to Light; otherwise switches to Dark.
  void toggleTheme() {
    state = (state == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
  }

  /// Explicitly sets the app to a specific theme mode (Light, Dark, or System).
  ///
  /// - [mode]: The desired ThemeMode to apply.
  /// How: Only updates state if the new mode is different from current mode.
  /// Why: Avoids unnecessary widget tree rebuilds.
  void setTheme(ThemeMode mode) {
    if (state != mode) {
      state = mode;
    }
  }

  /// Checks if Dark mode is currently active.
  bool get isDarkMode => state == ThemeMode.dark;

  /// Checks if Light mode is currently active.
  bool get isLightMode => state == ThemeMode.light;

  /// Checks if the app is following the system theme.
  bool get isSystemMode => state == ThemeMode.system;
}
