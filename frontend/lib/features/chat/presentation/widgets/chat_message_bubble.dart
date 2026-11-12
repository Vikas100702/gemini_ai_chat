import 'package:flutter/material.dart';
import 'package:gemini_ai_chat/core/constants/app_colors.dart';
import 'package:gemini_ai_chat/features/chat/domain/models/chat_message_model.dart';

/// Purpose:
/// Visual chat bubble widget responsible for displaying an individual message turn.
///
/// Task:
/// 1. Styles and positions user messages (right-aligned) vs. AI responses (left-aligned).
/// 2. Renders attached camera/gallery photos with memory-safe downscaling to prevent OOM.
/// 3. Switches between high-performance simple text during streaming and interactive
///    selectable text upon generation completion to avoid UI frame drops.
/// 4. Dynamically caps max bubble width for fluid responsive display on phones, tablets, and web.
class ChatMessageBubble extends StatelessWidget {
  /// What it does:
  /// Standard constructor for [ChatMessageBubble].
  ///
  /// Why it is needed:
  /// Requires the immutable [ChatMessageModel] containing message text, media,
  /// sender type, and status flags.
  ///
  /// How it works:
  /// Receives [message] and forwards the widget key for efficient list diffing.
  const ChatMessageBubble({super.key, required this.message});

  /// The message data model instance to render.
  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = message.isUser;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive layout adaptation:
    // Takes 80% screen width on mobile, capped at 560 logical pixels on tablets and web
    // to prevent uncomfortably stretched text lines.
    final double maxBubbleWidth = screenWidth > 720 ? 560.0 : screenWidth * 0.80;

    // Select semantic bubble background colors according to theme brightness
    final Color bubbleColor = isUser
        ? (isDark ? AppColors.userBubbleDark : AppColors.userBubbleLight)
        : (isDark ? AppColors.aiBubbleDark : AppColors.aiBubbleLight);

    return Align(
      // Right-align user bubbles, left-align AI bubbles
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18.0),
            topRight: const Radius.circular(18.0),
            bottomLeft: Radius.circular(isUser ? 18.0 : 4.0),
            bottomRight: Radius.circular(isUser ? 4.0 : 18.0),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8.0, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Attached Photo Rendering (Multimodal Media)
              if (message.hasMedia) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.memory(
                    message.imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180.0,
                    // Memory safety: caps memory raster cache decoding size
                    // to prevent decoding large multi-megapixel files in memory.
                    cacheWidth: 800,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100.0,
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        alignment: Alignment.center,
                        child: Text('Failed to render image payload', style: TextStyle(color: theme.colorScheme.error, fontSize: 12.0)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8.0),
              ],

              // 2. Message Text Content
              if (message.text.isNotEmpty) _buildMessageContent(theme, isUser, isDark),

              // 3. Active Streaming "Thinking..." Indicator
              if (message.isStreaming && message.text.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 14.0, height: 14.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: theme.colorScheme.primary)),
                      const SizedBox(width: 8.0),
                      Text(
                        'Thinking...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              // 4. Transmission Failure Warning
              if (message.status == MessageStatus.error) ...[
                const SizedBox(height: 6.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 14.0, color: theme.colorScheme.error),
                    const SizedBox(width: 4.0),
                    Text(
                      'Generation failed',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error, fontSize: 11.0, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// What it does:
  /// Conditionally switches between simple [Text] and interactive [SelectableText].
  ///
  /// Why it is needed:
  /// Rendering and calculating hit-tests for [SelectableText] on every token chunk
  /// drops UI frames and causes noticeable typing lag during high-frequency streaming.
  /// Standard [Text] is used while streaming, switching to [SelectableText] only once complete.
  ///
  /// How it works:
  /// - If `message.isStreaming` is true: returns lightweight [Text].
  /// - Once completed: returns [SelectableText] so users can copy code or answers.
  Widget _buildMessageContent(ThemeData theme, bool isUser, bool isDark) {
    final Color textColor = isUser
        ? (isDark ? AppColors.userBubbleTextDark : AppColors.userBubbleTextLight)
        : (isDark ? AppColors.aiBubbleTextDark : AppColors.aiBubbleTextLight);

    final TextStyle textStyle = theme.textTheme.bodyMedium?.copyWith(color: textColor, height: 1.45) ?? TextStyle(color: textColor, height: 1.45);

    if (message.isStreaming) {
      return Text(message.text, style: textStyle);
    }

    return SelectableText(message.text, style: textStyle);
  }
}
