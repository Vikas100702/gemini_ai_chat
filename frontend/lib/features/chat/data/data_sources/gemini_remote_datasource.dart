import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gemini_ai_chat/core/constants/app_constants.dart';
import 'package:gemini_ai_chat/core/errors/app_exception.dart';
import 'package:gemini_ai_chat/features/chat/domain/models/chat_message_model.dart';
import 'package:http/http.dart' as http;

/// Purpose:
/// The interface contract defining remote communication with the Google Gemini AI REST API.
///
/// Task:
/// 1. Declares real-time streaming operations using Server-Sent Events (SSE).
/// 2. Provides a disposal contract to abort in-flight HTTP connections and prevent memory leaks.
abstract interface class GeminiRemoteDataSource {
  /// What it does:
  /// Sends the prompt, attached image bytes, and conversation history to the Gemini API
  /// and yields text chunks as they arrive over the network.
  ///
  /// Why it is needed:
  /// Powers live token-by-token streaming in the chat UI.
  ///
  /// How it works:
  /// - [prompt]: User query or multimodal instruction.
  /// - [imageBytes]: Optional raw image bytes to analyze.
  /// - [history]: Prior conversation turns for multi-turn context.
  /// - [model]: Target Gemini model (defaults to Gemini 2.5 Flash).
  Stream<String> streamPrompt({
    required String prompt,
    Uint8List? imageBytes,
    List<ChatMessageModel> history = const [],
    GeminiModelType model = AppConstants.defaultModel,
  });

  /// What it does:
  /// Closes the active HTTP client and cleans up allocated network resources.
  ///
  /// Why it is needed:
  /// Prevents memory leaks and orphaned network sockets when the chat session ends.
  void dispose();
}

/// Purpose:
/// Production implementation of [GeminiRemoteDataSource] using raw HTTP requests
/// and Server-Sent Events (SSE) stream transformers.
///
/// Task:
/// 1. Formats multi-turn chat history and payloads into Gemini's expected JSON format.
/// 2. Streams and parses incoming SSE data lines (`data: {...}`) in real time.
/// 3. Maps network timeouts, connection drops, and API error codes into typed [AppException] objects.
class GeminiRemoteDataSourceImpl implements GeminiRemoteDataSource {
  /// What it does:
  /// Constructs the remote data-source with an optional [http.Client].
  ///
  /// Why it is needed:
  /// Allows passing mock HTTP clients during automated unit testing.
  ///
  /// How it works:
  /// Uses the provided client or initializes a standard [http.Client].
  GeminiRemoteDataSourceImpl({http.Client? client}) : _client = client ?? http.Client();

  /// The underlying HTTP client used for network requests.
  final http.Client _client;

  /// Internal flag tracking whether this data-source has already been closed.
  bool _isDisposed = false;

  /// What it does:
  /// Dispatches a streaming POST request to the Google Generative Language endpoint
  /// and yields textual tokens as they are decoded from the SSE byte stream.
  ///
  /// Why it is needed:
  /// Delivers low-latency text rendering so users see responses immediately.
  ///
  /// How it works:
  /// 1. Validates that the data-source is active and that a valid API key exists.
  /// 2. Assembles rolling conversation turns and serializes system instructions.
  /// 3. Sends the HTTP request with a strict timeout boundary.
  /// 4. Decodes the response body via UTF-8 and lines split by `\n`.
  /// 5. Safely extracts and yields candidate text parts from each `data: {...}` line without type-cast crashes.
  @override
  Stream<String> streamPrompt({
    required String prompt,
    Uint8List? imageBytes,
    List<ChatMessageModel> history = const [],
    GeminiModelType model = AppConstants.defaultModel,
  }) async* {
    // Step 1: Guard against executing queries on an already closed data-source
    if (_isDisposed) {
      throw const ApiException(message: 'Cannot execute a prompt on a closed or disposed DataSource.', code: 'DATASOURCE_DISPOSED');
    }

    // Step 2: Ensure API key is configured
    if (!AppConstants.hasValidApiKey) {
      throw const ApiException(message: 'Gemini API Key is missing. Pass it via --dart-define=GEMINI_API_KEY=your_key', code: 'MISSING_API_KEY');
    }

    // Step 3: Construct the streaming REST URL with SSE query parameter
    final Uri url = Uri.parse('${AppConstants.geminiBaseUrl}/${model.modelId}:streamGenerateContent?alt=sse&key=${AppConstants.geminiApiKey}');

    // Step 4: Assemble conversation history within rolling context limits
    final List<Map<String, dynamic>> contents = [];
    final boundedHistory = history.length > AppConstants.maxRollingHistoryTurns
        ? history.sublist(history.length - AppConstants.maxRollingHistoryTurns)
        : history;

    for (final message in boundedHistory) {
      contents.add(message.toGeminiContent());
    }

    // Step 5: Append the current user message turn
    final currentUserMessage = ChatMessageModel(id: '', sender: MessageSender.user, text: prompt, timestamp: DateTime.now(), imageBytes: imageBytes);
    contents.add(currentUserMessage.toGeminiContent());

    // Step 6: Construct the complete request payload including system prompt
    final Map<String, dynamic> requestPayload = {
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': AppConstants.defaultSystemInstruction},
        ],
      },
      'generationConfig': {'temperature': AppConstants.defaultTemperature},
    };

    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(requestPayload);

    // Step 7: Dispatch the request with an enterprise timeout guard
    http.StreamedResponse streamedResponse;
    try {
      final timeoutDuration = imageBytes != null ? AppConstants.imageUploadTimeout : AppConstants.requestTimeout;

      streamedResponse = await _client.send(request).timeout(timeoutDuration);
    } on TimeoutException catch (e, stackTrace) {
      throw RequestTimeoutException(
        message: 'The connection to Gemini AI timed out. Please try again.',
        code: 'REQUEST_TIMEOUT',
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw NetworkException(message: 'Network dispatch failed: $e', code: 'NETWORK_DISPATCH_ERROR', stackTrace: stackTrace);
    }

    // Step 8: Handle non-200 HTTP response codes
    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw ApiException(
        message: 'Gemini API returned status (${streamedResponse.statusCode}): $errorBody',
        statusCode: streamedResponse.statusCode,
        code: streamedResponse.statusCode == 429 ? 'RATE_LIMIT_EXCEEDED' : 'API_ERROR',
      );
    }

    // Step 9: Transform raw byte stream into discrete Server-Sent Event lines
    final linesStream = streamedResponse.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in linesStream) {
      final trimmed = line.trim();

      // Only lines starting with 'data: ' contain JSON token payloads
      if (!trimmed.startsWith('data: ')) continue;

      final jsonPayload = trimmed.substring(6).trim();
      if (jsonPayload.isEmpty) continue;

      String? chunkText;
      try {
        final dynamic decoded = jsonDecode(jsonPayload);
        if (decoded is Map<String, dynamic>) {
          // Defensive check: candidates is a List<dynamic> in JSON decoding
          final dynamic candidates = decoded['candidates'];
          if (candidates is List && candidates.isNotEmpty) {
            final dynamic firstCandidate = candidates.first;
            if (firstCandidate is Map<String, dynamic>) {
              final dynamic content = firstCandidate['content'];
              if (content is Map<String, dynamic>) {
                final dynamic parts = content['parts'];
                if (parts is List && parts.isNotEmpty) {
                  for (final dynamic part in parts) {
                    if (part is Map<String, dynamic> && part.containsKey('text')) {
                      final dynamic text = part['text'];
                      if (text is String && text.isNotEmpty) {
                        chunkText = (chunkText ?? '') + text;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[GeminiRemoteDataSourceImpl] SSE parsing error: $e');
        }
      }

      // Step 10: Yield the extracted token fragment to listeners
      if (chunkText != null && chunkText.isNotEmpty) {
        yield chunkText;
      }
    }
  }

  /// What it does:
  /// Closes the HTTP client safely and marks the instance as disposed.
  ///
  /// Why it is needed:
  /// Ensures active connections are released without throwing state errors.
  ///
  /// How it works:
  /// Checks `_isDisposed`; if false, closes `_client` and flips the flag to true.
  @override
  void dispose() {
    if (!_isDisposed) {
      _client.close();
      _isDisposed = true;
    }
  }
}
