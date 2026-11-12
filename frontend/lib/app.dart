import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_assets.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'features/chat/presentation/views/chat_view.dart';

/// Purpose:
/// The root application presentation shell and top-level MaterialApp coordinator.
///
/// Task:
/// 1. Observes the active [ThemeMode] reactively from [themeNotifierProvider].
/// 2. Configures Material 3 Light and Dark design themes from [AppTheme].
/// 3. Warms up bundled image assets into the image raster cache to prevent UI flicker.
/// 4. Provides a global tap-to-dismiss gesture safety layer to close soft keyboards smoothly.
class IterApp extends ConsumerStatefulWidget {
  /// What it is:
  /// Standard constructor for the root [IterApp] widget.
  ///
  /// Why it is needed:
  /// Serves as the top-level widget hosted directly inside [ProviderScope].
  const IterApp({super.key});

  @override
  ConsumerState<IterApp> createState() => _IterAppState();
}

class _IterAppState extends ConsumerState<IterApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm up bundled wallpaper assets into memory.
    // Why: Pre-caching prevents background flicker and frame drops when the chat view first renders.
    _precacheApplicationAssets();
  }

  /// What it does:
  /// Loads all bundled local image assets into the Flutter engine's image memory cache.
  ///
  /// Why it is needed:
  /// Eliminates the visual pop-in delay on initial application launch.
  ///
  /// How it works:
  /// Iterates through [AppAssets.allAssets] and executes [precacheImage] for each file.
  void _precacheApplicationAssets() {
    for (final assetPath in AppAssets.allAssets) {
      precacheImage(AssetImage(assetPath), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reactively watch current theme mode (Light, Dark, or System)
    final ThemeMode themeMode = ref.watch(themeNotifierProvider);

    return GestureDetector(
      // Global UX Feature: Tap anywhere outside a text field to dismiss the soft keyboard.
      // Why: Eliminates keyboard deadlocks and ensures a clean view of message bubbles.
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: MaterialApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,

        // Material 3 light and dark theme configurations
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,

        // Primary chat interface entry route
        home: const ChatView(),
      ),
    );
  }
}
