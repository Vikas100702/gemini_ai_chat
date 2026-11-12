import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_ai_chat/core/constants/app_assets.dart';
import 'package:gemini_ai_chat/core/constants/app_constants.dart';
import 'package:gemini_ai_chat/core/theme/theme_notifier.dart';
import 'package:gemini_ai_chat/core/utils/dialog_helper.dart';
import 'package:gemini_ai_chat/features/chat/domain/models/chat_message_model.dart';
import 'package:gemini_ai_chat/features/chat/presentation/notifiers/chat_notifier.dart';
import 'package:gemini_ai_chat/features/chat/presentation/notifiers/chat_state.dart';
import 'package:gemini_ai_chat/features/chat/presentation/widgets/chat_input_field.dart';
import 'package:gemini_ai_chat/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:image_picker/image_picker.dart';

/// Purpose:
/// The primary screen widget for the Iter AI Chat interface.
///
/// Task:
/// 1. Acts as the pure declarative UI ("Face") strictly separated from business logic.
/// 2. Observes [ChatState] and renders message history with an inverted scroll list.
/// 3. Listens for error transitions to present non-stacking modal dialogs via [DialogHelper].
/// 4. Adapts theme wallpapers, action buttons, and keyboard geometry seamlessly.
class ChatView extends ConsumerStatefulWidget {
  /// What it is:
  /// Standard constructor for [ChatView].
  ///
  /// Why it is needed:
  /// Serves as the top-level route destination for the chat module.
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  /// Controller managing scroll position and physics for the chat list.
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Initialize the scroll controller in the widget lifecycle
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    // Proactive Memory Management: Always dispose scroll controllers
    // to prevent memory leaks and dangling scroll position listeners.
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeNotifierProvider) == ThemeMode.dark;
    final chatState = ref.watch(chatNotifierProvider);

    // Defensive error listener:
    // Listens for error state changes without rebuilding the entire screen widget tree.
    // DialogHelper prevents stacking dialogs if multiple API failures occur consecutively.
    ref.listen<ChatState>(chatNotifierProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        DialogHelper.showErrorDialog(
          context,
          title: 'Transmission Error',
          message: next.errorMessage!,
          onConfirm: () => ref.read(chatNotifierProvider.notifier).clearError(),
        );
      }
    });

    // Resolve wallpaper asset through centralized AppAssets helper (Single Source of Truth)
    final String bgAsset = AppAssets.resolveChatBackground(isDark: isDark);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(AppConstants.appTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0)),
        actions: [
          // Gallery Image Analysis Action
          IconButton(
            onPressed: chatState.isLoading || chatState.isStreaming
                ? null
                : () => ref.read(chatNotifierProvider.notifier).pickAndSendMedia(source: ImageSource.gallery),
            icon: const Icon(Icons.image_search, size: 24.0),
            tooltip: 'Analyze Image from Gallery',
          ),

          // Camera Photo Capture & Analysis Action
          IconButton(
            onPressed: chatState.isLoading || chatState.isStreaming
                ? null
                : () => ref.read(chatNotifierProvider.notifier).pickAndSendMedia(source: ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined, size: 24.0),
            tooltip: 'Capture & Analyze',
          ),

          // Story Narration from Image Action
          IconButton(
            onPressed: chatState.isLoading || chatState.isStreaming
                ? null
                : () => ref
                      .read(chatNotifierProvider.notifier)
                      .pickAndSendMedia(source: ImageSource.gallery, customPrompt: AppConstants.storyImagePrompt),
            icon: const Icon(CupertinoIcons.book_fill, size: 22.0),
            tooltip: 'Narrate Story from Image',
          ),

          // Theme Mode Switcher Action
          IconButton(
            onPressed: () => ref.read(themeNotifierProvider.notifier).toggleTheme(),
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 22.0),
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgAsset),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low, // Minimizes GPU texture memory overhead
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              // 1. Message History Viewport
              Expanded(child: chatState.isEmpty ? _buildEmptyState(theme) : _buildMessageList(chatState)),

              // 2. Decoupled Chat Input Field & Attachment Bar
              ChatInputField(
                isLoading: chatState.isLoading || chatState.isStreaming,
                onSend: (text) {
                  ref.read(chatNotifierProvider.notifier).sendMessage(prompt: text);
                },
                onGalleryTap: () => ref.read(chatNotifierProvider.notifier).pickAndSendMedia(source: ImageSource.gallery),
                onCameraTap: () => ref.read(chatNotifierProvider.notifier).pickAndSendMedia(source: ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// What it does:
  /// Renders a centered welcome container when no messages exist in the conversation.
  ///
  /// Why it is needed:
  /// Provides immediate visual feedback to the user when starting a new session.
  ///
  /// How it works:
  /// Returns a decorated card with instructions to type or share an image.
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10.0, offset: const Offset(0, 4))],
        ),
        child: Text(
          'No messages yet. Ask anything or share an image.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.75)),
        ),
      ),
    );
  }

  /// What it does:
  /// Builds the inverted scrolling list of chat bubbles.
  ///
  /// Why it is needed:
  /// An inverted list (`reverse: true`) keeps the newest message anchored at the
  /// bottom right above the input box, which is standard for chat apps.
  ///
  /// How it works:
  /// 1. If tokens are actively streaming (`hasActiveStreamBubble`), it reserves
  ///    index 0 for the incoming streaming buffer.
  /// 2. Defensively checks message count to prevent `IndexOutOfBounds` crashes.
  /// 3. Assigns unique [ValueKey] instances to each bubble to ensure Flutter's
  ///    element diffing tree only repaints changed items.
  Widget _buildMessageList(ChatState chatState) {
    final bool hasActiveStreamBubble = chatState.isStreaming && chatState.activeStreamingText.isNotEmpty;
    final int totalCount = chatState.messages.length + (hasActiveStreamBubble ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Anchors the latest messages to the bottom
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // Render dynamic transient bubble for live token streaming at the bottom
        if (hasActiveStreamBubble && index == 0) {
          final activeMessage = ChatMessageModel(
            id: 'active_streaming_transient_bubble',
            sender: MessageSender.ai,
            text: chatState.activeStreamingText,
            timestamp: DateTime.now(),
            status: MessageStatus.streaming,
          );

          return ChatMessageBubble(key: const ValueKey('active_streaming_bubble'), message: activeMessage);
        }

        // Adjust index offset when active streaming bubble is shown
        final int messageIndex = hasActiveStreamBubble ? index - 1 : index;

        // Defensive boundary check
        if (messageIndex < 0 || messageIndex >= chatState.messages.length) {
          return const SizedBox.shrink();
        }

        final message = chatState.messages[messageIndex];
        return ChatMessageBubble(key: ValueKey(message.id), message: message);
      },
    );
  }
}
