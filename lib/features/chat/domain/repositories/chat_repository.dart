import 'dart:typed_data';

import 'package:gemini_ai_chat/core/constants/app_constants.dart';
import 'package:gemini_ai_chat/features/chat/domain/models/chat_message_model.dart';
import 'package:image_picker/image_picker.dart';

/// Purpose:
/// The domain contract (interface) defining all chat and multimodal capabilities.
///
/// Task:
/// 1. Enforces strict Separation of Concerns (SoC) by decoupling business logic from
///    concrete HTTP clients, third-party Gemini SDKs, and device hardware APIs.
/// 2. Defines streaming contracts for token chunks using conversational rolling context.
/// 3. Declares device camera/gallery image acquisition contracts.
///
/// Why it is an interface:
/// By depending on an abstract interface instead of a direct implementation, the
/// presentation layer (controllers/notifiers) can be unit-tested using mocks without
/// hitting live servers or requiring physical device hardware.
abstract interface class ChatRepository {
  /// What it does:
  /// Streams real-time response token chunks from Google Gemini AI.
  ///
  /// Why it is needed:
  /// Streaming delivers an immediate, interactive typing experience rather than
  /// forcing the user to wait several seconds for a full monolithic response.
  ///
  /// How it works:
  /// - [prompt]: The text query or instruction submitted by the user.
  /// - [imageBytes]: Optional raw bytes of an image to analyze alongside the prompt.
  /// - [history]: Previous conversation turns to preserve conversational context.
  /// - [model]: The chosen Gemini model type (defaults to Gemini 2.5 Flash).
  ///
  /// Returns:
  /// A cold [Stream] that emits string token fragments as they arrive over
  /// the Server-Sent Events (SSE) connection from the backend.
  Stream<String> streamPrompt({
    required String prompt,
    Uint8List? imageBytes,
    List<ChatMessageModel> history = const [],
    GeminiModelType model = AppConstants.defaultModel,
  });

  /// What it does:
  /// Captures a photo using the device camera or selects an image from the gallery.
  ///
  /// Why it is needed:
  /// Abstracts platform-specific image picking so that the UI does not directly
  /// deal with hardware permissions, file paths, or platform channel exceptions.
  ///
  /// How it works:
  /// - [source]: Specifies whether to open [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// Returns:
  /// A [Future] resolving to the compressed raw image bytes ([Uint8List]), or
  /// `null` if the user cancelled the operation without selecting an image.
  Future<Uint8List?> pickImage(ImageSource source);

  /// What it does:
  /// Cancels in-flight requests and frees active network or hardware resources.
  ///
  /// Why it is needed:
  /// Prevents memory leaks and lingering background sockets when users leave
  /// the chat screen or switch conversation sessions.
  ///
  /// How it works:
  /// Instructs the underlying data sources to close open HTTP clients and abort
  /// pending asynchronous tasks.
  void dispose();
}
