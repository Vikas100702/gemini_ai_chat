import 'dart:async';

import 'package:flutter/foundation.dart';

import 'failure.dart';

/// Purpose:
/// Base class for all internal technical exceptions thrown across the application.
///
/// Task:
/// Captures technical error details, error codes, HTTP status codes, and stack traces,
/// then converts them cleanly into user-facing [Failure] objects.
@immutable
abstract class AppException implements Exception {
  const AppException({required this.message, this.code, this.statusCode, this.stackTrace});

  final String message;
  final String? code; // Short machine-readable code (e.g., 'NETWORK_OFFLINE', 'API_SERVER_ERROR').
  final int? statusCode; // HTTP response status code if the error comes from a web request.
  final StackTrace? stackTrace; // The exact line-by-line code trace where the error occurred.

  Failure toFailure(); // Converts this technical exception into a user-friendly domain [Failure].

  @override
  String toString() => '$runtimeType(message: $message, code: $code, statusCode: $statusCode)';
}

/// Thrown when there is no internet connection or DNS lookup fails.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network connection failed. Please verify your internet connection.',
    super.code = 'NETWORK_OFFLINE',
    super.stackTrace,
  });

  @override
  Failure toFailure() => NetworkFailure(message: message, code: code, stackTrace: stackTrace);
}

/// Thrown when a network request takes longer than the allowed time limit.
class RequestTimeoutException extends AppException {
  const RequestTimeoutException({
    super.message = 'The server took too long to respond. Please try again.',
    super.code = 'REQUEST_TIMEOUT',
    super.stackTrace,
  });

  @override
  Failure toFailure() => TimeoutFailure(message: message, code: code, stackTrace: stackTrace);
}

/// Thrown when the Gemini AI API returns an error response (such as 400, 403, 429, or 500).
class ApiException extends AppException {
  const ApiException({required super.message, super.code = 'API_SERVER_ERROR', super.statusCode, super.stackTrace});

  @override
  Failure toFailure() => ServerFailure(message: message, code: code, statusCode: statusCode, stackTrace: stackTrace);
}

/// Thrown when an uploaded image exceeds 4 MB size boundary.
class PayloadSizeLimitException extends AppException {
  const PayloadSizeLimitException({
    super.message = 'The selected image exceeds the maximum supported threshold of 4MB.',
    super.code = 'IMAGE_TOO_LARGE',
    super.stackTrace,
  });

  @override
  Failure toFailure() => PayloadSizeFailure(message: message, code: code, stackTrace: stackTrace);
}

/// Thrown when camera, photo library, or file picker access fails or permissions are denied.
class MediaDeviceException extends AppException {
  const MediaDeviceException({required super.message, super.code = 'HARDWARE_IO_ERROR', super.stackTrace});

  @override
  Failure toFailure() => MediaHardwareFailure(message: message, code: code, stackTrace: stackTrace);
}

/// Purpose:
/// Central error interpreter that turns any unknown thrown object into a safe [Failure].
///
/// Task:
/// 1. Catches raw errors without letting the app crash.
/// 2. Remains 100% compatible with Flutter Web without importing dart:io directly.
/// 3. Normalizes timeouts, platform exceptions, and unexpected errors.
abstract final class ExceptionHandler {
  /// Converts any dynamic error and stack trace into a predictable [Failure].
  ///
  /// - [error]: The caught exception or error object.
  /// - [stackTrace]: Optional stackTrace where the failure happened.
  static Failure handle(Object error, [StackTrace? stackTrace]) {
    // 1. If it is already one of our custom exceptions, map it directly.
    if (error is AppException) {
      return error.toFailure();
    }

    // 2. Handle request timeouts gracefully.
    if (error is TimeoutException) {
      return TimeoutFailure(message: 'The server took too long to respond. Please try again.', stackTrace: stackTrace);
    }

    // 3. Handle argument errors (e.g. invalid base64 image data or empty keys).
    if (error is ArgumentError) {
      return PayloadSizeFailure(message: error.message?.toString() ?? 'Invalid input payload provided.', stackTrace: stackTrace);
    }

    // 4. Safe network error detection that works on both Mobile and Web
    // (Avoids direct dart:io SocketException reference to prevent Web compilation crashes).
    final String errorText = error.toString().toLowerCase();
    if (errorText.contains('socketexception') ||
        errorText.contains('network is unreachable') ||
        errorText.contains('failed host lookup') ||
        errorText.contains('connection refused') ||
        errorText.contains('xmlhttprequest error')) {
      return NetworkFailure(message: 'Unable to connect to the server. Please check your network connection.', stackTrace: stackTrace);
    }

    // 5. Fallback for completely unexpected runtime errors.
    return UnknownFailure(message: 'An unexpected error occurred. Please try again later.', stackTrace: stackTrace);
  }
}
