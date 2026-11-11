import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../data_sources/gemini_remote_datasource.dart';
import '../data_sources/media_local_datasource.dart';

/// What it is:
/// Riverpod provider exposing the remote Gemini API data source.
///
/// Why it is needed:
/// Delivers an application-scoped data source instance so that active network
/// connections are preserved between user message dispatches.
///
/// How it works:
/// Instantiates [GeminiRemoteDataSourceImpl] and maintains its lifecycle for the session.
final geminiRemoteDataSourceProvider = Provider<GeminiRemoteDataSource>((ref) {
  final dataSource = GeminiRemoteDataSourceImpl();
  ref.onDispose(() {
    dataSource.dispose();
  });
  return dataSource;
});

/// What it is:
/// Riverpod provider exposing the local camera and gallery hardware data source.
///
/// Why it is needed:
/// Supplies a mockable local media handler for taking or picking photos.
///
/// How it works:
/// Instantiates and preserves [MediaLocalDataSourceImpl].
final mediaLocalDataSourceProvider = Provider<MediaLocalDataSource>((ref) {
  return MediaLocalDataSourceImpl();
});

/// What it is:
/// Global Riverpod provider exposing the enterprise [ChatRepository].
///
/// Why it is needed:
/// Acts as the single entry point for controllers/notifiers to stream AI responses
/// and pick photos without premature garbage-collection disposal crashes.
///
/// How it works:
/// Injects both persistent data sources into [ChatRepositoryImpl].
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDataSource = ref.watch(geminiRemoteDataSourceProvider);
  final localDataSource = ref.watch(mediaLocalDataSourceProvider);

  return ChatRepositoryImpl(remoteDataSource: remoteDataSource, localDataSource: localDataSource);
});

/// Purpose:
/// Production implementation of the [ChatRepository] domain contract.
///
/// Task:
/// 1. Bridges the presentation layer with remote Gemini AI endpoints and local hardware.
/// 2. Converts low-level network errors and platform exceptions into domain-safe Failures.
/// 3. Prevents memory leaks by ensuring HTTP connections and local tasks are disposed cleanly.
class ChatRepositoryImpl implements ChatRepository {
  /// What it is:
  /// Constructor injecting both the remote and local media data sources.
  ///
  /// Why it is needed:
  /// Follows the Dependency Inversion Principle, allowing easy unit testing with mocks.
  ///
  /// How it works:
  /// Assigns the passed data source contracts to private final member variables.
  const ChatRepositoryImpl({required GeminiRemoteDataSource remoteDataSource, required MediaLocalDataSource localDataSource})
    : _remoteDataSource = remoteDataSource,
      _localDataSource = localDataSource;

  final GeminiRemoteDataSource _remoteDataSource;
  final MediaLocalDataSource _localDataSource;

  /// What it does:
  /// Dispatches a prompt and optional image to Gemini AI and emits token strings.
  ///
  /// Why it is needed:
  /// Connects the user's conversation to the live Server-Sent Events (SSE) stream.
  ///
  /// How it works:
  /// 1. Calls `_remoteDataSource.streamPrompt`.
  /// 2. Attaches an asynchronous `.handleError(...)` transformer so that network drops
  ///    or API limits emitted during the stream are converted cleanly into typed [Failure]
  ///    objects without triggering unhandled zone crashes.
  @override
  Stream<String> streamPrompt({
    required String prompt,
    Uint8List? imageBytes,
    List<ChatMessageModel> history = const [],
    GeminiModelType model = AppConstants.defaultModel,
  }) {
    try {
      return _remoteDataSource.streamPrompt(prompt: prompt, imageBytes: imageBytes, history: history, model: model).handleError((error, stackTrace) {
        // Defensive logging for developer observability platforms (e.g. Sentry)
        if (kDebugMode) {
          debugPrint('[ChatRepositoryImpl.streamPrompt Stream Error]: $error\n$stackTrace');
        }
        // Map raw error to a domain Failure
        throw ExceptionHandler.handle(error, stackTrace);
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ChatRepositoryImpl.streamPrompt Synchronous Exception]: $e\n$stackTrace');
      }
      throw ExceptionHandler.handle(e, stackTrace);
    }
  }

  /// What it does:
  /// Interacts with local camera or photo gallery hardware to retrieve image bytes.
  ///
  /// Why it is needed:
  /// Allows the user to select an image for multimodal question answering.
  ///
  /// How it works:
  /// 1. Calls `_localDataSource.pickImage(source)`.
  /// 2. If an exception occurs (e.g., permission denied, out of memory, or file corrupt),
  ///    intercepts it and throws a structured domain [Failure].
  @override
  Future<Uint8List?> pickImage(ImageSource source) async {
    try {
      return await _localDataSource.pickImage(source);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ChatRepositoryImpl.pickImage Exception]: $e\n$stackTrace');
      }
      throw ExceptionHandler.handle(e, stackTrace);
    }
  }

  /// What it does:
  /// Releases network connections and closes active HTTP sessions.
  ///
  /// Why it is needed:
  /// Satisfies the domain interface contract and ensures lingering network streams
  /// do not cause memory leaks when tearing down the session.
  ///
  /// How it works:
  /// Calls `dispose()` on the remote data source.
  @override
  void dispose() {
    _remoteDataSource.dispose();
  }
}
