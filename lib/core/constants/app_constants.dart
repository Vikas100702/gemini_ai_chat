import 'package:flutter/foundation.dart';

enum GeminiModelType {
  flash(
    modelId: 'gemini-2.5-flash',
    displayName: 'Gemini 2.5 Flash (Ultra Fast)',
    description: 'Optimized for high-speed streaming and conversational tasks.',
  ),
  pro(
    modelId: 'gemini-2.5-pro',
    displayName: 'Gemini 2.5 Pro (Deep Reasoning)',
    description: 'Advanced reasoning, complex coding, and multimodal analysis.',
  );

  const GeminiModelType({required this.modelId, required this.displayName, required this.description});

  final String modelId;
  final String displayName;
  final String description;
}

@immutable
abstract final class AppConstants {
  // Pass credentials securely via build/run flag:
  // flutter run --dart-define=GEMINI_API_KEY=your_actual_key_here
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Defensive assertion ensuring the application never executes without credentials.
  static bool get hasValidApiKey => geminiApiKey.trim().isNotEmpty;

  // Endpoint Identifiers
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  // Default Runtime AI Settings
  static const GeminiModelType defaultModel = GeminiModelType.flash;
  static const double defaultTemperature = 0.7;
  static const int maxRollingHistoryTurns = 10; // Maintains conversation memory

  // Enterprise System Prompt for Identity & Robust Responses
  static const String defaultSystemInstruction =
      'You are Iter, a helpful, ultra-fast, and precise AI assistant. Provide concise, clear, and high-impact answers.';

  // Application Identifiers
  static const String appTitle = 'Iter';
  static const String userSenderId = 'user_client';
  static const String userSenderName = 'User';
  static const String aiSenderId = 'iter_gemini';
  static const String aiSenderName = 'Iter AI';

  // Multimodal Action Prompts
  static const String defaultImagePrompt = 'Describe this image accurately and concisely.';
  static const String storyImagePrompt = 'Narrate a creative and engaging story based on this image.';

  // Asset References
  static const String darkChatBg = 'assets/darkChat.png';
  static const String lightChatBg = 'assets/lightChat.png';

  // Performance & Safety Thresholds
  static const Duration requestTimeout = Duration(seconds: 35);
  static const Duration tokenTickerInterval = Duration(milliseconds: 25); // UI frame buffer
  static const int maxImageSizeInBytes = 4 * 1024 * 1024; // 4MB guard limit
}
