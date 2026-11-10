import 'dart:convert';

import 'package:flutter/foundation.dart';

/// What it is:
/// An enum indicating who sent the chat message.
///
/// Why it is needed:
/// The app needs to know whether to style the bubble as a user bubble (aligned right)
/// or an AI response bubble (aligned left), and how to format roles when sending to Gemini.
enum MessageSender { user, ai }

/// What it is:
/// An enum tracking the transmission lifecycle of a message.
///
/// Why it is needed:
/// Tells the UI when to display loaders, token typing animations, success indicators,
/// or failure error icons without guesswork.
///
/// How it works:
/// - [sending]: Message is being packaged or media is being uploaded.
/// - [streaming]: Response tokens are actively arriving over the network stream.
/// - [sent]: Message delivery or generation has completed successfully.
/// - [error]: An error occurred during transmission or generation.
enum MessageStatus { sending, streaming, sent, error }

/// Purpose:
/// The primary immutable data model representing a single conversation turn in the chat.
///
/// Task:
/// 1. Holds message metadata (ID, sender, text content, timestamps, and image bytes).
/// 2. Converts internal message state into Gemini API-compliant JSON formats.
/// 3. Performs memory-safe, fast equality checks over byte arrays to avoid UI lag.
@immutable
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.imageBytes,
    this.imageMimeType = 'image/jpeg',
  });

  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final Uint8List? imageBytes;
  final String imageMimeType;

  bool get hasMedia => imageBytes != null && imageBytes!.isNotEmpty;

  /// What it is:
  /// A boolean getter checking if the message is currently receiving streaming text chunks.
  ///
  /// Why it is needed:
  /// Informs the UI to render non-selectable text or smooth typing indicators.
  ///
  /// How it works:
  /// Compares `status` against `MessageStatus.streaming`.
  bool get isStreaming => status == MessageStatus.streaming;
  bool get isUser => sender == MessageSender.user;

  /// What it is:
  /// A method that creates a copy of this message with specific fields updated.
  ///
  /// Why it is needed:
  /// `ChatMessageModel` is immutable (`@immutable`). To change a field (like appending
  /// incoming text or updating the status to error), we must produce a new instance
  /// without mutating the existing one.
  ///
  /// How it works:
  /// Evaluates each parameter: if a new value is passed, it uses it; otherwise,
  /// it retains the existing property value.
  ChatMessageModel copyWith({
    String? id,
    MessageSender? sender,
    String? text,
    DateTime? timestamp,
    MessageStatus? status,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      imageBytes: imageBytes ?? this.imageBytes,
      imageMimeType: imageMimeType ?? this.imageMimeType,
    );
  }

  /// What it is:
  /// Transforms this message into the Google Gemini API `contents` format.
  ///
  /// Why it is needed:
  /// The Gemini REST API requires a specific JSON schema with `role` ('user' or 'model')
  /// and an array of `parts` containing either inline base64 data or plain text.
  ///
  /// How it works:
  /// 1. Creates an empty list of parts.
  /// 2. If an image is attached, encodes the raw bytes into a base64 string inside `inlineData`.
  /// 3. If text exists, trims it and appends it as a `text` part.
  /// 4. Maps the sender to the Gemini role (`user` -> 'user', `ai` -> 'model').
  Map<String, dynamic> toGeminiContent() {
    final List<Map<String, dynamic>> parts = [];

    // Step 1: Base64-encode image payload if present
    if (hasMedia) {
      parts.add({
        'inlineData': {'mimeType': imageMimeType, 'data': base64Encode(imageBytes!)},
      });
    }

    // Step 2: Append text payload if non-empty
    if (text.trim().isNotEmpty) {
      parts.add({'text': text.trim()});
    }

    // Step 3: Package into Gemini API content node
    return {'role': isUser ? 'user' : 'model', 'parts': parts};
  }

  /// What it is:
  /// Custom equality operator comparing this message with another object.
  ///
  /// Why it is needed:
  /// By default, Dart compares instances by memory reference. In reactive state
  /// management (Riverpod/GetX), lists of messages are frequently evaluated.
  /// Overriding `==` prevents the UI from re-rendering bubbles when data hasn't changed.
  ///
  /// How it works:
  /// 1. Short-circuits with `identical()` if both variables share the same pointer.
  /// 2. Verifies the runtime type matches.
  /// 3. Compares primitive fields (`id`, `sender`, `text`, `status`, `timestamp`).
  /// 4. Delegates image byte comparisons to `_fastBytesEquals` to prevent slow memory loops.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sender == other.sender &&
          text == other.text &&
          status == other.status &&
          timestamp == other.timestamp &&
          imageMimeType == other.imageMimeType &&
          _fastBytesEquals(imageBytes, other.imageBytes);

  /// What it is:
  /// Generates a numeric hash code representing this object.
  ///
  /// Why it is needed:
  /// Dart requires that any two objects considered equal by `==` must return
  /// the identical `hashCode`. Without this, collections like `Set` or `Map` break.
  ///
  /// How it works:
  /// Combines hash values of all scalar fields. For `imageBytes`, it uses its byte length
  /// (`lengthInBytes`) instead of hashing every individual byte, avoiding severe frame jank.
  @override
  int get hashCode =>
      id.hashCode ^
      sender.hashCode ^
      text.hashCode ^
      timestamp.hashCode ^
      status.hashCode ^
      imageMimeType.hashCode ^
      (imageBytes?.lengthInBytes ?? 0);

  /// What it is:
  /// A high-performance helper to compare two byte buffers safely.
  ///
  /// Why it is needed:
  /// Comparing high-resolution image byte arrays (e.g., 2MB to 4MB) byte-by-byte on every
  /// build frame burns CPU cycles and drops UI frames.
  ///
  /// How it works:
  /// 1. Returns true if both references point to the exact same byte buffer in memory.
  /// 2. Returns false if only one of them is null.
  /// 3. Returns false immediately if byte lengths differ (e.g., 2,000 bytes vs 3,500 bytes).
  /// 4. Falls back to byte-by-byte check (`listEquals`) only when lengths match exactly.
  static bool _fastBytesEquals(Uint8List? a, Uint8List? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.lengthInBytes != b.lengthInBytes) return false;
    return listEquals(a, b);
  }
}
