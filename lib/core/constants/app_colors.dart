import 'package:flutter/material.dart';

@immutable
abstract final class AppColors {
  // Brand Palette Primitives
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color accentBlue = Color(0xFF3B82F6);

  // Surface & Canvas Tokens (Light Theme)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLight = Color(0xFFF1F5F9);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Surface & Canvas Tokens (Dark Theme)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceContainerDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Chat Bubble Tokens (Light Theme)
  // Why: Explicit bubble colors prevent hardcoding inside UI chat widgets.
  static const Color userBubbleLight = Color(0xFF2563EB);
  static const Color userBubbleTextLight = Color(0xFFFFFFFF);
  static const Color aiBubbleLight = Color(0xFFF1F5F9);
  static const Color aiBubbleTextLight = Color(0xFF0F172A);

  // Chat Bubble Tokens (Dark Theme)
  static const Color userBubbleDark = Color(0xFF2563EB);
  static const Color userBubbleTextDark = Color(0xFFFFFFFF);
  static const Color aiBubbleDark = Color(0xFF1E293B);
  static const Color aiBubbleTextDark = Color(0xFFF8FAFC);

  // Code Block Surfaces (For Markdown rendering of AI responses)
  static const Color codeBackgroundLight = Color(0xFFE2E8F0);
  static const Color codeBackgroundDark = Color(0xFF0B1120);

  // Semantic & Feedback Tokens
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorRedDark = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color warningAmber = Color(0xFFD97706);

  // Subtle Border, Divider & Elevation Tokens
  static const Color lightDivider = Color(0x1A0F172A); // 10% opacity black
  static const Color darkDivider = Color(0x1AF8FAFC); // 10% opacity white
  static const Color shadowColor = Color(0x0A000000); // 4% opacity black
}
