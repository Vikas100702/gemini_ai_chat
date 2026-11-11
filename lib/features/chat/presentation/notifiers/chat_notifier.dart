import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_ai_chat/core/constants/app_constants.dart';
import 'package:gemini_ai_chat/core/errors/app_exception.dart';
import 'package:gemini_ai_chat/core/errors/failure.dart';
import 'package:gemini_ai_chat/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:gemini_ai_chat/features/chat/domain/models/chat_message_model.dart';
import 'package:gemini_ai_chat/features/chat/domain/repositories/chat_repository.dart';
import 'package:gemini_ai_chat/features/chat/presentation/notifiers/chat_state.dart';
import 'package:image_picker/image_picker.dart';

/// What it is:
/// Riverpod provider exposing the [ChatNotifier] controller and its immutable [ChatState].
///
/// Why it is needed:
/// Supplies the single state management controller for the chat interface.
/// Notice: Maintained as a persistent provider (not autoDispose) to keep the chat
/// session and active streams alive during keyboard toggles and screen rotations.
///
/// How it works:
/// Instantiates [ChatNotifier] using its default constructor.
final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

/// Purpose:
/// The primary business logic controller (the "Brain") for the Chat feature.
///
/// Task:
/// 1. Manages chat message history and input states.
/// 2. Dispatches prompts and image payloads to the [ChatRepository].
/// 3. Safely handles real-time token streaming with zero memory leaks or stream overlaps.
/// 4. Converts raw errors into sanitized, human-readable domain [Failure] messages.
class ChatNotifier extends Notifier<ChatState> {
  /// Active subscription receiving incoming tokens from Gemini AI.
  StreamSubscription<String>? _streamSubscription;

  /// Temporary ID assigned to the incoming AI response message turn.
  String _activeAiMessageId = '';

  /// What it does:
  /// Initializes the state notifier when first created.
  ///
  /// Why it is needed:
  /// Sets up default state and registers a cleanup hook to cancel any active stream
  /// if the provider is ever destroyed or reset.
  ///
  /// How it works:
  /// Registers [ref.onDispose] and returns an empty [ChatState.initial()].
  @override
  ChatState build() {
    ref.onDispose(() {
      _cancelActiveStream();
    });
    return ChatState.initial();
  }

  /// Convenience getter to access the injected [ChatRepository].
  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  /// What it does:
  /// Safely cancels any active SSE network stream and clears its subscription.
  ///
  /// Why it is needed:
  /// Prevents memory leaks, socket retention, and overlapping token streams if the
  /// user sends another message while one is already generating.
  ///
  /// How it works:
  /// Cancels `_streamSubscription` and sets the reference back to null.
  void _cancelActiveStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  /// What it does:
  /// Captures a photo using the camera or picks an image from the gallery,
  /// then immediately dispatches it with an accompanying prompt to Gemini AI.
  ///
  /// Why it is needed:
  /// Powers the top-bar actions and multimodal attachment buttons.
  ///
  /// How it works:
  /// 1. Sets `isLoading: true` while hardware image selection runs.
  /// 2. If the user cancels the picker, resets loading to false.
  /// 3. If an image is selected, forwards the image bytes directly to [sendMessage].
  /// 4. Catches hardware/permission exceptions and presents a clean domain error.
  Future<void> pickAndSendMedia({required ImageSource source, String? customPrompt}) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final Uint8List? imageBytes = await _repository.pickImage(source);

      // If user backed out without selecting a photo, abort cleanly
      if (imageBytes == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Dispatch prompt with the selected image payload
      await sendMessage(prompt: customPrompt ?? AppConstants.defaultImagePrompt, imageBytes: imageBytes);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ChatNotifier.pickAndSendMedia Exception]: $e\n$stackTrace');
      }

      // Convert raw error into a domain Failure
      final Failure failure = ExceptionHandler.handle(e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  /// What it does:
  /// Dispatches a user prompt and optional image payload to Gemini AI and
  /// subscribes to the incoming token stream.
  ///
  /// Why it is needed:
  /// Core operational method orchestrating conversation turns and AI responses.
  ///
  /// How it works:
  /// 1. Validates prompt and payload constraints.
  /// 2. Cancels any in-flight stream to prevent stream collisions.
  /// 3. Appends the user's message to state and prepares a placeholder AI message.
  /// 4. Subscribes to `_repository.streamPrompt` to accumulate tokens chunk by chunk.
  /// 5. Automatically finalizes the message on completion or handles stream errors.
  Future<void> sendMessage({required String prompt, Uint8List? imageBytes}) async {
    final cleanPrompt = prompt.trim();

    // Guard against blank dispatches with no image payload
    if (cleanPrompt.isEmpty && (imageBytes == null || imageBytes.isEmpty)) {
      return;
    }

    // Cancel any prior stream so old tokens don't leak into the new turn
    _cancelActiveStream();

    final now = DateTime.now();

    // 1. Create the user message turn
    final userMessage = ChatMessageModel(
      id: now.microsecondsSinceEpoch.toString(),
      sender: MessageSender.user,
      text: cleanPrompt.isNotEmpty ? cleanPrompt : AppConstants.defaultImagePrompt,
      timestamp: now,
      status: MessageStatus.sent,
      imageBytes: imageBytes,
    );

    // 2. Generate a distinct ID for the upcoming AI response turn
    _activeAiMessageId = (now.microsecondsSinceEpoch + 1).toString();

    // 3. Update state: add user message and switch into streaming mode
    state = state.copyWith(
      messages: [userMessage, ...state.messages],
      isLoading: false,
      isStreaming: true,
      activeStreamingText: '',
      clearError: true,
    );

    try {
      // Pass chronological history (oldest first) to maintain context window
      final chronologicalHistory = state.messages.reversed.toList();

      final stream = _repository.streamPrompt(prompt: userMessage.text, imageBytes: imageBytes, history: chronologicalHistory);

      _streamSubscription = stream.listen(
        (chunk) {
          _appendChunk(chunk);
        },
        onError: (Object error, StackTrace stackTrace) {
          _handleStreamError(error, stackTrace);
        },
        onDone: () {
          _finalizeAiMessage();
        },
        cancelOnError: true,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ChatNotifier.sendMessage Exception]: $e\n$stackTrace');
      }
      _handleStreamError(e, stackTrace);
    }
  }

  /// What it does:
  /// Appends newly arrived string token chunks to the active streaming buffer.
  ///
  /// Why it is needed:
  /// Isolates rapid token updates into `activeStreamingText` so that historical
  /// message items in the list view do not re-render repeatedly.
  ///
  /// How it works:
  /// Updates `activeStreamingText` on [ChatState] with the combined buffer.
  void _appendChunk(String chunk) {
    if (chunk.isEmpty) return;
    state = state.copyWith(activeStreamingText: '${state.activeStreamingText}$chunk', isStreaming: true);
  }

  /// What it does:
  /// Concludes the streaming turn once the network stream emits `onDone`.
  ///
  /// Why it is needed:
  /// Converts the transient streaming buffer into a permanent [ChatMessageModel]
  /// and resets streaming flags.
  ///
  /// How it works:
  /// 1. Cleans up the active stream subscription.
  /// 2. If valid text was received, marks the message as `sent`.
  /// 3. If empty, falls back to a helpful warning and sets status to `error`.
  /// 4. Resets `activeStreamingText` and `isStreaming`.
  void _finalizeAiMessage() {
    _cancelActiveStream();

    final finalContent = state.activeStreamingText.trim();
    final bool hasContent = finalContent.isNotEmpty;

    final completedAiMessage = ChatMessageModel(
      id: _activeAiMessageId,
      sender: MessageSender.ai,
      text: hasContent ? finalContent : 'No response received. Please check your network connection.',
      timestamp: DateTime.now(),
      status: hasContent ? MessageStatus.sent : MessageStatus.error,
    );

    state = state.copyWith(messages: [completedAiMessage, ...state.messages], isStreaming: false, activeStreamingText: '', isLoading: false);
  }

  /// What it does:
  /// Handles errors emitted by the network stream or during dispatch.
  ///
  /// Why it is needed:
  /// Preserves any partially received text so the user doesn't lose what was already
  /// typed, while attaching an error flag and surfacing a sanitized error message.
  ///
  /// How it works:
  /// 1. Closes the active stream subscription.
  /// 2. Translates the error into a sanitized domain [Failure].
  /// 3. If partial content arrived, saves it as an error-flagged message.
  /// 4. Updates state with the human-readable error string.
  void _handleStreamError(Object error, [StackTrace? stackTrace]) {
    _cancelActiveStream();

    final Failure failure = ExceptionHandler.handle(error, stackTrace);
    final partialContent = state.activeStreamingText.trim();

    if (partialContent.isNotEmpty) {
      final partialAiMessage = ChatMessageModel(
        id: _activeAiMessageId,
        sender: MessageSender.ai,
        text: partialContent,
        timestamp: DateTime.now(),
        status: MessageStatus.error,
      );

      state = state.copyWith(
        messages: [partialAiMessage, ...state.messages],
        isStreaming: false,
        activeStreamingText: '',
        isLoading: false,
        errorMessage: failure.message,
      );
    } else {
      state = state.copyWith(isStreaming: false, activeStreamingText: '', isLoading: false, errorMessage: failure.message);
    }
  }

  /// What it does:
  /// Clears the active error message from state.
  ///
  /// Why it is needed:
  /// Invoked by dialog dismiss callbacks so the error dialog does not re-trigger.
  ///
  /// How it works:
  /// Sets `clearError: true` on the state copy.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
