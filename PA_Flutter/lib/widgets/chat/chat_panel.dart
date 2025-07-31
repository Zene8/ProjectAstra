// lib/features/chat/ui/chat_panel.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive Flutter
import 'package:projectastra/models/chat_models.dart'; // Your models
import 'package:projectastra/widgets/chat/chat_input_bar.dart';
import 'package:projectastra/widgets/chat/chat_message_bubble.dart';
import 'package:projectastra/services/chat_api_service.dart';
import 'package:projectastra/widgets/chat/code_element_highlighter.dart'
    show CodeElementHighlighter, kDefaultDarkCodeTheme, kDefaultLightCodeTheme;

// Define this constant, possibly in a shared file or your main.dart
const String chatMessagesBoxName = 'chatMessagesBox';

class ChatPanel extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isMobile;
  final Color? backgroundColor;

  const ChatPanel({
    super.key,
    this.onClose,
    required this.isMobile,
    this.backgroundColor,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  bool _isSending = false;

  final ChatApiService _chatApiService = ChatApiService();
  late Box<ChatMessage> _chatMessagesBox; // Hive box instance

  @override
  void initState() {
    super.initState();
    // Get the already opened box from main.dart
    _chatMessagesBox = Hive.box<ChatMessage>(chatMessagesBoxName);
    _loadMessages();
  }

  void _loadMessages() {
    // values is an Iterable<ChatMessage>, convert to List
    // The order is based on the auto-incrementing integer keys Hive uses for .add()
    final List<ChatMessage> loadedMessages = _chatMessagesBox.values.toList();

    // Sort by timestamp to ensure correct chronological order
    loadedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (mounted) {
      setState(() {
        _messages.addAll(loadedMessages);
      });
      // Scroll to bottom after messages are loaded and UI is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_messages.isNotEmpty) {
          _scrollToBottom();
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final userInputText = _textController.text.trim();
    if (userInputText.isEmpty || _isSending) return;

    final userMessage = ChatMessage(
      type: MessageType.user,
      text: userInputText,
      timestamp: DateTime.now(), // Add timestamp
    );

    // Update UI first for responsiveness
    setState(() {
      _messages.add(userMessage);
      _isSending = true;
    });
    await _chatMessagesBox.add(userMessage); // Persist user message
    _textController.clear();
    _scrollToBottom();

    final placeholderMessage = ChatMessage(
      type: MessageType.ai,
      text: "...",
      thinkingText: "Astra is processing...",
      timestamp: DateTime.now(), // Add timestamp
    );

    int placeholderUiIndex = -1;
    if (mounted) {
      setState(() {
        _messages.add(placeholderMessage);
        placeholderUiIndex = _messages.length - 1; // Store UI index
      });
    }
    // Save placeholder to Hive and get its auto-generated key
    final placeholderHiveKey = await _chatMessagesBox.add(placeholderMessage);
    _scrollToBottom();

    try {
      final Map<String, dynamic> apiResponse =
          await _chatApiService.sendMessageToBackend(userInputText);
      final String actualFinalAnswer = apiResponse['final_answer'] as String? ??
          "Sorry, I couldn't get a response.";
      final String? actualThinkingProcess = apiResponse['thinking'] as String?;

      if (!mounted) return;

      final finalAIMessage = ChatMessage(
        type: MessageType.ai,
        text: actualFinalAnswer,
        thinkingText: actualThinkingProcess,
        timestamp: placeholderMessage
            .timestamp, // Keep placeholder's timestamp or use DateTime.now()
      );

      // Update the placeholder in Hive using its specific key
      await _chatMessagesBox.put(placeholderHiveKey, finalAIMessage);

      // Update in UI list
      setState(() {
        if (placeholderUiIndex != -1 &&
            placeholderUiIndex < _messages.length &&
            _messages[placeholderUiIndex].text == "...") {
          _messages[placeholderUiIndex] = finalAIMessage;
        } else {
          // Fallback: if UI index tracking somehow failed, find by content (less reliable)
          int fallbackIndex = _messages.lastIndexWhere(
            (msg) => msg.type == MessageType.ai && msg.text == "...",
          );
          if (fallbackIndex != -1) {
            _messages[fallbackIndex] = finalAIMessage;
          } else {
            _messages.add(
              finalAIMessage,
            ); // Should not happen if placeholder was added
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      print("ChatPanel: Error sending message - $e");

      // If an error occurs, we might want to remove the placeholder from Hive
      if (_chatMessagesBox.containsKey(placeholderHiveKey)) {
        await _chatMessagesBox.delete(placeholderHiveKey);
      }

      setState(() {
        // Remove placeholder from UI list
        if (placeholderUiIndex != -1 &&
            placeholderUiIndex < _messages.length &&
            _messages[placeholderUiIndex].text == "...") {
          _messages.removeAt(placeholderUiIndex);
        } else {
          // Fallback removal
          _messages.removeWhere(
            (msg) =>
                msg.type == MessageType.ai &&
                msg.text == "..." &&
                msg.timestamp == placeholderMessage.timestamp,
          );
        }

        String errorMessage = e.toString().replaceFirst("Exception: ", "");
        final errorChatMessage = ChatMessage(
          type: MessageType.ai,
          text: "Error: $errorMessage",
          timestamp: DateTime.now(), // Add timestamp
        );
        _messages.add(errorChatMessage);
        _chatMessagesBox.add(errorChatMessage); // Persist error message
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _handleVoice() {
    if (_isSending) return;
    print('Voice input activated from ChatPanel');
  }

  void _handleAttach() {
    if (_isSending) return;
    print('Attachment triggered from ChatPanel');
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final CodeElementHighlighter currentCodeHighlighter =
        CodeElementHighlighter(
      theme: isDarkMode ? kDefaultDarkCodeTheme : kDefaultLightCodeTheme,
    );

    return Container(
      color:
          widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: !widget.isMobile,
              child: ListView.builder(
                // Adding a key can sometimes help Flutter's diffing, especially if list order changes often.
                // For append-only with occasional updates, it's often fine without.
                // key: ValueKey(_messages.length),
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ChatMessageBubble(
                    // Use a unique key if message objects can be reordered or frequently updated
                    // key: ValueKey(message.timestamp.millisecondsSinceEpoch), // Example
                    message: message,
                    codeHighlighter: currentCodeHighlighter,
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
            child: ChatInputBar(
              textController: _textController,
              onSend: _handleSend,
              onVoice: _handleVoice,
              onAttach: _handleAttach,
              disabled: _isSending,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    // It's generally good practice to close boxes when they are no longer needed,
    // though Hive often handles flushing well. For a box used throughout the app's
    // lifecycle, closing might happen at the app's main dispose if at all.
    // If ChatPanel is frequently created/destroyed and the box isn't needed elsewhere,
    // you could close it here. For this example, we'll assume it stays open.
    // Hive.box(chatMessagesBoxName).close(); // Example if you want to close it
    super.dispose();
  }
}
