import 'package:flutter/material.dart';

/// Purpose:
/// Adds handy shortcuts to [BuildContext] to access themes, screen sizes,
/// and responsive layout checks without repeating long boilerplate code.
///
/// Task:
/// 1. Provides fast access to themes, colors, and typography.
/// 2. Measures screen size, safe-area paddings, and on-screen keyboard height safely.
/// 3. Detects device categories (mobile, tablet, desktop) for adaptive responsive UI.
extension BuildContextX on BuildContext {
  /// Fast accessor for the active [ThemeData].
  /// How: Reads theme data associated with this build context.
  ThemeData get theme => Theme.of(this);

  /// Fast accessor for the active [ColorScheme].
  /// How: Pulls semantic colors (primary, surface, background, error).
  ColorScheme get colorScheme => theme.colorScheme;

  /// Fast accessor for the active [TextTheme].
  /// How: Pulls font styling (headline, title, body, label).
  TextTheme get textTheme => theme.textTheme;

  /// Retrieves the overall screen dimensions without subscribing to unnecessary rebuilds.
  /// How: Uses [MediaQuery.sizeOf] for high-performance non-rebuilding reads.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Total available screen width in logical pixels.
  double get screenWidth => screenSize.width;

  /// Total available screen height in logical pixels.
  double get screenHeight => screenSize.height;

  /// Safe-area padding boundaries (cutouts, notch, home indicator bar).
  /// How: Uses [MediaQuery.paddingOf] to keep content safe from screen edges.
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  /// Soft-keyboard view insets.
  /// How: Uses [MediaQuery.viewInsetsOf] to track screen area obscured by keyboard.
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  /// Height of the virtual keyboard currently open on screen.
  double get keyboardHeight => viewInsets.bottom;

  /// Whether a soft-keyboard is currently visible.
  bool get isKeyboardOpen => keyboardHeight > 0;

  /// Device classification flags for responsive UI adaptation.
  /// Why: Ensures the chat interface scales correctly across phones, tablets, and web.
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  /// Helper to calculate proportional screen width percentage (0.0 to 1.0).
  /// Example: context.percentWidth(0.5) returns 50% of the screen width.
  double percentWidth(double factor) => screenWidth * factor;

  /// Helper to calculate proportional screen height percentage (0.0 to 1.0).
  /// Example: context.percentHeight(0.3) returns 30% of the screen height.
  double percentHeight(double factor) => screenHeight * factor;
}

/// Purpose:
/// Formats raw byte counts into human-readable digital storage units.
///
/// Task:
/// Converts file byte numbers into neat strings (B, KB, MB, GB) with defensive checks.
extension FileSizeX on num {
  /// Converts raw byte counts into human-readable formatted string units (KB, MB, GB).
  ///
  /// How it works:
  /// - Guards against negative numbers or invalid values.
  /// - Divides incrementally by 1024 to find the appropriate scale.
  String toReadableFileSize() {
    if (isNaN || this <= 0) return '0 B';
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Purpose:
/// Provides defensive sanitation and formatting shortcuts for nullable Strings.
///
/// Task:
/// Handles null checks, blank spaces, and safe truncation without throwing exceptions.
extension StringSanitationX on String? {
  /// Checks whether an optional string is null, empty, or contains only whitespace.
  /// Why: Avoids accidental sending of blank messages to the AI model.
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  /// Defensively truncates string length with an ellipsis (...) without crashing.
  ///
  /// - [maxLength]: Maximum number of characters allowed before cutting off.
  /// How it works:
  /// - Checks boundary conditions (negative lengths, null strings).
  /// - Trims and attaches an ellipsis when text exceeds length limits.
  String truncate(int maxLength) {
    if (this == null) return '';
    if (maxLength <= 0) return '';
    final text = this!;
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
