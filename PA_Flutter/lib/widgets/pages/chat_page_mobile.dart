import 'package:projectastra/widgets/chat/chat_app_bar.dart'; // Adjust path as needed
import 'package:projectastra/widgets/chat/chat_panel.dart';
import 'package:flutter/material.dart';

class MobileChatPage extends StatelessWidget {
  final VoidCallback onNavigateAway;

  const MobileChatPage({super.key, required this.onNavigateAway});

  @override
  Widget build(BuildContext context) {
    var color = const Color(0xFF101828);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      resizeToAvoidBottomInset: true,
      appBar: ChatAppBar(
        backgroundColor: color,
        onMenuPressed: onNavigateAway,
        onNewChatPressed: () {
          print("MobileChatPage: New Chat pressed");
          // Consider how to signal ChatPanel to clear messages or use a new ChatPanel instance via state management
        },
        onMoreOptionsPressed: () {
          print("MobileChatPage: More Options pressed");
        },
      ),
      body: ChatPanel(isMobile: true, backgroundColor: color),
    );
  }
}
