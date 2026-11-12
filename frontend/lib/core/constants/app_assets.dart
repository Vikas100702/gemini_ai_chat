import 'package:flutter/foundation.dart';

@immutable
abstract final class AppAssets {
  // Chat Background Images
  static const String darkChatBg = 'assets/darkChat.png';
  static const String lightChatBg = 'assets/lightChat.png';

  /// Complete manifest of all bundled local image assets.
  /// Why: Can be passed to pre cache Image() during app startup to avoid image popping or flicker.
  static const List<String> allAssets = [darkChatBg, lightChatBg];

  /// Chooses the correct chat background image path based on the current theme brightness.
  ///
  /// - [isDark]: Pass true if dark mode is active, false for light mode.
  /// How: Returns the dark chat wallpaper if isDark is true, otherwise returns the light wallpaper.
  static String resolveChatBackground({required bool isDark}) {
    return isDark ? darkChatBg : lightChatBg;
  }
}
