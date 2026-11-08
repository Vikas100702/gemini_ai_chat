import 'package:flutter/material.dart';
import 'package:gemini_ai_chat/core/errors/failure.dart';

/// Purpose:
/// Coordinates dialogs and snack-bars across the app from a single place.
///
/// Task:
/// 1. Prevents opening multiple dialogs on top of each other when many errors happen at once.
/// 2. Ensures screens are still on screen (mounted) before showing alerts.
/// 3. Converts technical system errors into friendly, readable text.
abstract final class DialogHelper {
  static bool _isDialogOpen = false; // Prevents multiple dialogs from stacking.
  static bool get isDialogOpen => _isDialogOpen; // Check whether an error dialog is currently open.

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required dynamic message,
    String buttonText = 'OK',
    VoidCallback? onConfirm,
  }) async {
    // Stop if a dialog is already showing or if the screen is no longer visible.
    // Why: Prevents app crashes from interacting with destroyed screens.
    if (_isDialogOpen || !context.mounted) return;

    _isDialogOpen = true; // Lock the dialog so no other dialog can open at the same time.

    // Users should see clean messages, not raw code crashes.
    final String displayMessage = message is Failure ? message.message : (message?.toString() ?? 'An unexpected error occurred.');

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          final theme = Theme.of(dialogContext);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            title: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            content: Text(
              displayMessage,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.85), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Only pop if the dialog view is still mounted and can pop.
                  // How: Checks dialogContext.mounted and canPop() before closing.
                  if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }
                  onConfirm?.call(); // Run the callback if provided.
                },
                child: Text(
                  buttonText,
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      // Unlock the flag when the dialog closes, even if something went wrong.
      // Why: Ensures future dialogs can open properly without getting stuck.
      _isDialogOpen = false;
    }
  }

  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return; // Check if the screen is still active before doing anything.

    final theme = Theme.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.hideCurrentSnackBar(); // Remove any currently showing snack-bar immediately.

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: isError ? theme.colorScheme.onError : theme.colorScheme.onPrimary)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? theme.colorScheme.error : theme.colorScheme.primary,
        duration: duration,
        action: action,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }
}
