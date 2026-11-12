import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gemini_ai_chat/core/constants/app_colors.dart';

@immutable
abstract final class AppTheme {
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primaryBlue,
      secondary: AppColors.primaryBlueDark,
      surface: AppColors.surfaceLight,
      surfaceContainerHighest: AppColors.surfaceContainerLight,
      error: AppColors.errorRed,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      outline: AppColors.lightDivider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      dividerColor: AppColors.lightDivider,

      // Ensures phone status bar icons are easily visible (dark icons on light background)
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      ),

      // Clean card styling for message bubbles and modal panels
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      ),

      // Modal dialog presentation settings
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        titleTextStyle: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
      ),

      // Snack-bars styling for non-intrusive notifications
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryBlue,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),

      // Chat input box default styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLight,
        hintStyle: const TextStyle(color: AppColors.textSecondaryLight),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24.0), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      ),

      // Consistent cursor and selection highlight colors for text selection
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryBlue,
        selectionColor: AppColors.accentBlue,
        selectionHandleColor: AppColors.primaryBlue,
      ),

      // Circular loading indicators styling
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryBlue),
    );
  }

  /// Production Dark Theme configuration.
  /// How: Delivers optimized O-LED contrast while preventing eye strain in low-light environments.
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primaryBlue,
      secondary: AppColors.accentBlue,
      surface: AppColors.surfaceDark,
      surfaceContainerHighest: AppColors.surfaceContainerDark,
      error: AppColors.errorRedDark,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
      outline: AppColors.darkDivider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      dividerColor: AppColors.darkDivider,

      // Ensures phone status bar icons are easily visible (light icons on dark background)
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
      ),

      // Clean card styling for message bubbles and modal panels
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      ),

      // Modal dialog presentation settings
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        titleTextStyle: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
      ),

      // Snack-bars styling for non-intrusive notifications
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceContainerDark,
        contentTextStyle: const TextStyle(color: AppColors.textPrimaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),

      // Chat input box default styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerDark,
        hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24.0), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      ),

      // Consistent cursor and selection highlight colors for text selection
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accentBlue,
        selectionColor: AppColors.primaryBlueDark,
        selectionHandleColor: AppColors.accentBlue,
      ),

      // Circular loading indicators styling
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.accentBlue),
    );
  }
}
