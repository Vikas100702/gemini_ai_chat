import 'package:dash_chat_2/dash_chat_2.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';


class Methods{
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> chat = [];
  late final ChatUser geminiUser;
  void setState(VoidCallback fn) {
    fn();
  }

  void _sendMessage(ChatMessage chatMessage, List<ChatMessage> chat,
      Gemini gemini, ChatUser geminiUser) {
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

  void _sendGalleryMediaChat(ChatUser currentUser) async {
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

      _sendMessage(chatMessage, chat, gemini, geminiUser);
    }
  }

  void _sendStoryChat(ChatUser currentUser) async {
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

      _sendMessage(chatMessage, chat, gemini, geminiUser);
    }
  }

  void _sendCameraMediaChat(ChatUser currentUser) async {
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

      _sendMessage(chatMessage, chat, gemini, geminiUser);
    }
  }
}
