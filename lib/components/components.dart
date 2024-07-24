import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gemini_ai_chat/methods/methods.dart';
import 'package:gemini_ai_chat/theme/themeNotifier.dart';

Widget _chatUI(ThemeMode currentTheme, ChatUser currentUser, List<ChatMessage> chat){
  // final currentTheme = ref.watch(themeProvider);
  Methods m = Methods();
  return Container(
    height: double.maxFinite,
    width: double.maxFinite,
    decoration: BoxDecoration(
      image: DecorationImage(
        image: (currentTheme == ThemeMode.dark)
            ? const AssetImage("assets/darkChat.png")
            : const AssetImage("assets/lightChat.png"),
        fit: BoxFit.cover,
        // opacity: 100,
        filterQuality: FilterQuality.high,
      ),
    ),
    // child: DashChat(
    //   inputOptions: const InputOptions(),
    //   messageOptions: const MessageOptions(
    //       showCurrentUserAvatar: true,
    //       currentUserContainerColor: Colors.blue,
    //       currentUserTimeTextColor: Colors.blueGrey,
    //       timeTextColor: Colors.red,
    //       timeFontSize: 10,
    //       showTime: true
    //   ),
    //   currentUser: currentUser,
    //
    //   messages: chat,
    // ),
  );
}