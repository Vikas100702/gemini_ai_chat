import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// What it is:
/// The primary application entry point and bootstrapping routine.
///
/// Why it is needed:
/// Initializes the Flutter engine, attaches global crash safety nets, and launches
/// the root widget tree wrapped in Riverpod's [ProviderScope].
///
/// How it works:
/// 1. Wraps entire execution in [runZonedGuarded] to catch uncaught asynchronous errors.
/// 2. Ensures the Flutter binary binding is initialized before running plugins.
/// 3. Registers [FlutterError.onError] and [PlatformDispatcher.onError] to catch layout
///    and platform errors before they can crash the process.
/// 4. Mounts [IterApp] inside a [ProviderScope].
void main() {
  // Run the app inside a protected execution zone to catch uncaught async exceptions.
  runZonedGuarded<Future<void>>(
    () async {
      // Step 1: Ensure Flutter widget and engine bindings are fully ready.
      // Why: Must be called before interacting with native platform channels or plugins.
      WidgetsFlutterBinding.ensureInitialized();

      // Step 2: Catch framework, layout, and widget build exceptions.
      // Why: Keeps the UI from crashing to a grey/red screen in production by logging cleanly.
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _logObservabilityError(details.exception, details.stack ?? StackTrace.current, context: 'FlutterError.onError (Layout/Widget Error)');
      };

      // Step 3: Catch platform and root isolate errors (Flutter engine level).
      // Why: Acts as a safety net for background threads and native channel failures.
      PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
        _logObservabilityError(error, stackTrace, context: 'PlatformDispatcher.onError (Engine/Isolate Error)');
        return true; // Mark as handled so the OS does not force-kill the application.
      };

      // Step 4: Launch the root widget tree wrapped in Riverpod's ProviderScope.
      // Why: ProviderScope holds and manages all application state providers.
      runApp(const ProviderScope(child: IterApp()));
    },
    (Object error, StackTrace stackTrace) {
      // Step 5: Catch any stray async/microtask error that escaped the Flutter framework.
      _logObservabilityError(error, stackTrace, context: 'runZonedGuarded Root Safety Net (Uncaught Async Error)');
    },
  );
}

/// What it is:
/// Centralized crash telemetry and observability dispatcher.
///
/// Why it is needed:
/// Provides a single point to send errors to production monitoring platforms
/// (such as Sentry, Datadog, or Firebase Crashlytics) while formatting debug logs.
///
/// How it works:
/// - In debug mode: Prints structured, readable diagnostic blocks to the terminal console.
/// - In production mode: Forward errors and stack traces directly to your observability crash reporter.
void _logObservabilityError(Object error, StackTrace stackTrace, {required String context}) {
  if (kDebugMode) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[OBSERVABILITY CRASH REPORT]');
    debugPrint('Context   : $context');
    debugPrint('Timestamp : ${DateTime.now().toIso8601String()}');
    debugPrint('Error     : $error');
    debugPrint('StackTrace:\n$stackTrace');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  } else {
    // Production integration hook:
    // e.g., FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: context);
    // e.g., Sentry.captureException(error, stackTrace: stackTrace);
  }
}
