import 'dart:io';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../methods/methods.dart';
import '../theme/themeNotifier.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final Methods methods;


  final Gemini gemini = Gemini.instance;
  List<ChatMessage> chat = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini");

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            (currentTheme == ThemeMode.dark) ? Colors.black : Colors.white,
        title: Text(
          "Iter",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 34,
            color:
                (currentTheme == ThemeMode.dark) ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              onPressed: () {
                _sendGalleryMediaChat();
              },
              icon: Icon(
                Icons.image_search,
                color: (currentTheme == ThemeMode.dark)
                    ? Colors.white
                    : Colors.black,
                size: 30,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () {
                _sendCameraMediaChat();
              },
              icon: Icon(
                Icons.camera_alt_outlined,
                color: (currentTheme == ThemeMode.dark)
                    ? Colors.white
                    : Colors.black,
                size: 30,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () {
                _sendStoryChat();
              },
              icon: Icon(
                CupertinoIcons.book_fill,
                color: (currentTheme == ThemeMode.dark)
                    ? Colors.white
                    : Colors.black,
                size: 30,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: IconButton(
              onPressed: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              icon: (currentTheme == ThemeMode.dark)
                  ? const Icon(
                      Icons.light_mode,
                      color: Colors.white,
                    )
                  : const Icon(
                      Icons.dark_mode,
                      color: Colors.black,
                    ),
            ),
          ),
        ],
      ),
      // appBar: AppBar(
      body: _chatUI()
    );
  }

  Widget _chatUI() {
    final currentTheme = ref.watch(themeProvider);
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
      child: DashChat(
        inputOptions: const InputOptions(),
        messageOptions: const MessageOptions(
          showCurrentUserAvatar: true,
          currentUserContainerColor: Colors.blue,
          currentUserTimeTextColor: Colors.blueGrey,
          timeTextColor: Colors.red,
          timeFontSize: 10,
          showTime: true
        ),
        currentUser: currentUser,
        onSend: _sendMessage,
        messages: chat,
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage)  {
    setState(() {
      chat = [chatMessage, ...chat];
    });

    try {
      String questions = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }
      gemini
          .streamGenerateContent(
        questions,
        images: images,
      )
          .listen(
            (event) {
          ChatMessage? lastChat = chat.firstOrNull;
          if (lastChat != null && lastChat.user == geminiUser) {
            lastChat = chat.removeAt(0);
            String? response = event.content?.parts?.fold(
              "",
                  (previous, current) => "$previous ${current.text}",
            ) ??
                "";

            lastChat.text += response;
            setState(
                  () {
                chat = [lastChat!, ...chat];
              },
            );
          } else {
            String? response = event.content?.parts?.fold(
              "",
                  (previous, current) => "$previous ${current.text}",
            ) ??
                "";
            ChatMessage chatMessage = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: response,
            );

            setState(
                  () {
                chat = [chatMessage, ...chat];
              },
            );
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _sendGalleryMediaChat() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe the given image.",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          )
        ],
      );

      _sendMessage(chatMessage);
    }
  }

  void _sendStoryChat() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Narrate a creative story based on the given image.",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          )
        ],
      );

      _sendMessage(chatMessage);
    }
  }

  void _sendCameraMediaChat() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.camera);

    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe the image.",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          )
        ],
      );

      _sendMessage(chatMessage);
    }
  }


}
