import 'package:flutter/foundation.dart';
import 'package:gemini_ai_chat/features/chat/domain/models/chat_message_model.dart';

/// Purpose:
/// Immutable presentation state holding the entire UI data contract for the Chat screen.
///
/// Task:
/// 1. Stores the chronological list of completed message turns.
/// 2. Manages UI loading, sending, and streaming state flags.
/// 3. Isolates real-time streaming text tokens in a transient buffer to prevent frame drops.
/// 4. Carries human-readable error telemetry for modal dialogs and snackbars.
@immutable
class ChatState {
  /// What it is:
  /// The default constructor creating an immutable snapshot of the chat screen state.
  ///
  /// Why it is needed:
  /// Ensures all properties are compile-time constants or immutable structures.
  ///
  /// How it works:
  /// Assigns defaults for all optional parameters to ensure a safe initial state.
  const ChatState({this.messages = const [], this.isLoading = false, this.isStreaming = false, this.activeStreamingText = '', this.errorMessage});

  /// What it is:
  /// Factory constructor providing the initial baseline state when the app launches.
  ///
  /// Why it is needed:
  /// Gives Riverpod notifiers a clean, centralized starting point.
  ///
  /// How it works:
  /// Returns a const [ChatState] with empty messages and no errors.
  factory ChatState.initial() => const ChatState();

  /// The immutable sequence of completed conversation turns (both user and AI).
  final List<ChatMessageModel> messages;

  /// Global loading flag active during hardware image picking or network dispatch.
  final bool isLoading;

  /// High-frequency flag indicating that AI response tokens are actively streaming.
  final bool isStreaming;

  /// Transient buffer holding incoming text chunks for the message currently being streamed.
  /// Why: Isolates high-frequency token updates so the entire message history doesn't re-render.
  final String activeStreamingText;

  /// User-facing error message. Set when an operation fails, cleared upon user dismissal.
  final String? errorMessage;

  /// What it is:
  /// A boolean helper checking if an error is currently active.
  ///
  /// Why it is needed:
  /// Lets UI views listen for error state transitions cleanly.
  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;

  /// What it is:
  /// A boolean helper checking if the conversation has no messages yet.
  ///
  /// Why it is needed:
  /// Tells the view when to show the empty placeholder graphic and starter prompts.
  bool get isEmpty => messages.isEmpty && !isStreaming;

  /// What it is:
  /// A boolean helper determining whether the user is allowed to send a new message.
  ///
  /// Why it is needed:
  /// Disables input buttons while an image is uploading or a response is being generated.
  bool get canSendMessage => !isLoading && !isStreaming;

  /// What it is:
  /// Creates a copy of this state with updated fields.
  ///
  /// Why it is needed:
  /// In reactive clean architecture, state objects are immutable. Modifying state
  /// requires emitting a brand-new instance with only the desired fields altered.
  ///
  /// How it works:
  /// - Evaluates each argument: replaces with the new value if provided, else keeps the old one.
  /// - [clearError]: If true, forces [errorMessage] to `null` regardless of its current value.
  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? activeStreamingText,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      activeStreamingText: activeStreamingText ?? this.activeStreamingText,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// What it is:
  /// Custom equality operator comparing this state snapshot to another.
  ///
  /// Why it is needed:
  /// Riverpod compares the old state to the new state using `==`. If both are equal,
  /// widget rebuilds are discarded, preventing unnecessary CPU and GPU rendering cycles.
  ///
  /// How it works:
  /// 1. Short-circuits with `identical()` for matching object pointers.
  /// 2. Verifies matching runtime type.
  /// 3. Checks scalar fields (`isLoading`, `isStreaming`, `activeStreamingText`, `errorMessage`).
  /// 4. Compares the messages list element-by-element using [listEquals].
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          isStreaming == other.isStreaming &&
          activeStreamingText == other.activeStreamingText &&
          errorMessage == other.errorMessage &&
          listEquals(messages, other.messages);

  /// What it is:
  /// Generates a hash code for this state instance.
  ///
  /// Why it is needed:
  /// Enforces the Dart contract that equal objects must have identical hash codes.
  ///
  /// How it works:
  /// Combines hashes of all fields, including [Object.hashAll] on messages.
  @override
  int get hashCode => Object.hash(isLoading, isStreaming, activeStreamingText, errorMessage, Object.hashAll(messages));

  @override
  String toString() => 'ChatState(messagesCount: ${messages.length}, isLoading: $isLoading, isStreaming: $isStreaming, hasError: $hasError)';
}
