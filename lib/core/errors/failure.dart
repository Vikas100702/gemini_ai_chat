import 'package:flutter/foundation.dart';

/// Purpose:
/// The standard error class used across the domain and UI layers.
///
/// Task:
/// 1. Shields users from cryptic low-level crashes by providing clean messages.
/// 2. Keeps debugging details (error codes and stack traces) for developers and logs.
/// 3. Ensures value equality so UI state managers can compare errors reliably.
@immutable
abstract class Failure {
  const Failure({required this.message, this.code, this.stackTrace});

  final String message;
  final String? code; // Optional machine-readable code (e.g., 'NETWORK_OFFLINE', 'TIMEOUT').
  final StackTrace? stackTrace; // Optional stack trace for developer debugging and crash reporting.

  /// Exports structured failure data for logging platforms (Sentry, Crashlytics).
  /// Why: Gives developers full visibility into production failures without exposing raw crashes to users.
  Map<String, dynamic> toLogMap() {
    return {'type': runtimeType.toString(), 'message': message, 'code': code, 'stackTrace': stackTrace?.toString()};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Failure && runtimeType == other.runtimeType && message == other.message && code == other.code;

  @override
  int get hashCode => Object.hash(runtimeType, message, code);

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// Dispatched when the device has lost internet connectivity or server host lookup fails.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Network connection failed. Please check your internet connection.',
    super.code = 'NETWORK_OFFLINE',
    super.stackTrace,
  });
}

/// Dispatched when an API call or streaming response takes longer than the allowed time limit.
class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'The server took too long to respond. Please try again.', super.code = 'REQUEST_TIMEOUT', super.stackTrace});
}

/// Dispatched when the Gemini AI backend responds with an error code (e.g., rate limits, invalid prompts).
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code = 'SERVER_ERROR', super.stackTrace, this.statusCode});

  final int? statusCode; // HTTP response status code (e.g., 400, 401, 403, 429, 500).

  @override
  Map<String, dynamic> toLogMap() {
    final map = super.toLogMap();
    map['statusCode'] = statusCode;
    return map;
  }

  @override
  bool operator ==(Object other) => super == other && other is ServerFailure && statusCode == other.statusCode;

  @override
  int get hashCode => Object.hash(super.hashCode, statusCode);
}

/// Dispatched when camera, gallery, or local file access encounters a hardware or permission error.
class MediaHardwareFailure extends Failure {
  const MediaHardwareFailure({required super.message, super.code = 'MEDIA_HARDWARE_ERROR', super.stackTrace});
}

/// Dispatched when an uploaded image exceeds our 4MB payload safety boundary.
class PayloadSizeFailure extends Failure {
  const PayloadSizeFailure({
    super.message = 'The selected image is too large. Maximum supported size is 4MB.',
    super.code = 'PAYLOAD_TOO_LARGE',
    super.stackTrace,
  });
}

/// Dispatched when an unexpected runtime exception occurs that does not match a known category.
class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'An unexpected error occurred. Please try again later.', super.code = 'UNKNOWN_FAILURE', super.stackTrace});
}
