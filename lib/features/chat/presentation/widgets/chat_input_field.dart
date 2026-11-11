import 'package:flutter/material.dart';

/// Purpose:
/// The primary interactive text input field and media attachment action bar.
///
/// Task:
/// 1. Captures user message text and coordinates sending dispatches.
/// 2. Provides quick action triggers for Camera and Gallery image pickers.
/// 3. Prevents memory leaks by cleanly managing [TextEditingController] and [FocusNode].
/// 4. Handles on-screen keyboard (IME) animations smoothly across Mobile, Tablet, and Web.
class ChatInputField extends StatefulWidget {
  /// What it does:
  /// Standard constructor for [ChatInputField].
  ///
  /// Why it is needed:
  /// Takes required callbacks to notify the parent view of user interactions without
  /// keeping any business logic inside this widget (Strict Separation of Concerns).
  ///
  /// How it works:
  /// Accepts [onSend], [onGalleryTap], [onCameraTap], and [isLoading] status flags.
  const ChatInputField({super.key, required this.onSend, required this.onGalleryTap, required this.onCameraTap, this.isLoading = false});

  /// Callback dispatched when the user taps Send or presses keyboard enter.
  final ValueChanged<String> onSend;

  /// Callback dispatched when the gallery attachment button is pressed.
  final VoidCallback onGalleryTap;

  /// Callback dispatched when the camera photo button is pressed.
  final VoidCallback onCameraTap;

  /// Whether the AI assistant is currently generating or an image is uploading.
  final bool isLoading;

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  /// Controller managing the text content of the input box.
  late final TextEditingController _textController;

  /// Focus node managing keyboard focus and native IME connection.
  late final FocusNode _inputFocusNode;

  @override
  void initState() {
    super.initState();
    // Initialize text controller and focus node in the widget lifecycle
    _textController = TextEditingController();
    _inputFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // Proactive Memory Management: Always dispose controllers and focus nodes
    // to prevent memory leaks and dangling window listener callbacks.
    _textController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  /// What it does:
  /// Processes message submission when the send button or return key is hit.
  ///
  /// Why it is needed:
  /// Cleans up the text, validates that it is not empty, and emits the send callback.
  ///
  /// How it works:
  /// 1. Reads and trims the controller text.
  /// 2. Aborts if empty or if generation is already in progress.
  /// 3. Fires [widget.onSend] with the cleaned string.
  /// 4. Clears the text field while maintaining keyboard connection smoothly.
  void _handleSubmitted() {
    final cleanText = _textController.text.trim();

    // Guard against empty submits or sending while busy
    if (cleanText.isEmpty || widget.isLoading) return;

    widget.onSend(cleanText);
    _textController.clear();

    // Keep focus so the user can continue typing consecutive messages smoothly
    if (!_inputFocusNode.hasFocus) {
      _inputFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Compute safe-area bottom inset to respect phone gesture navigation bars
    final double bottomPadding = mediaQuery.viewInsets.bottom > 0 ? 8.0 : (mediaQuery.padding.bottom > 0 ? mediaQuery.padding.bottom : 8.0);

    return Material(
      color: theme.scaffoldBackgroundColor,
      elevation: 0,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 6.0, bottom: bottomPadding),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1), width: 1.0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Gallery attachment button
              IconButton(
                iconSize: 22,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: widget.isLoading ? null : widget.onGalleryTap,
                icon: Icon(Icons.image_outlined, color: widget.isLoading ? theme.disabledColor : theme.colorScheme.primary),
                tooltip: 'Attach Image from Gallery',
              ),

              // Camera photo capture button
              IconButton(
                iconSize: 22,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: widget.isLoading ? null : widget.onCameraTap,
                icon: Icon(Icons.camera_alt_outlined, color: widget.isLoading ? theme.disabledColor : theme.colorScheme.primary),
                tooltip: 'Take Photo with Camera',
              ),

              // Multiline primary input text field
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: TextField(
                    controller: _textController,
                    focusNode: _inputFocusNode,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.send,
                    minLines: 1,
                    maxLines: 4,
                    enabled: true,
                    // Keep enabled so soft keyboard never abruptly drops
                    autofocus: false,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                    onSubmitted: (_) => _handleSubmitted(),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.isLoading ? 'AI is thinking...' : 'Type a message...',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 1.2),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Dispatch button with animated loading indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: IconButton.filled(
                  iconSize: 20,
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: widget.isLoading ? null : _handleSubmitted,
                  icon: widget.isLoading
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                      : const Icon(Icons.arrow_upward),
                  tooltip: 'Send Message',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
