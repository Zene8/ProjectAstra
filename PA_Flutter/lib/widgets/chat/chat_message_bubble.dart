import 'package:flutter/material.dart'; // Or 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md; // ✅ // THIS IS THE KEY
// ... your other imports for models, highlighter ...
import 'package:projectastra/models/chat_models.dart';
import 'package:projectastra/widgets/chat/code_element_highlighter.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

//import 'package:url_launcher/url_launcher.dart'; // Uncomment if you use launchUrl

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final CodeElementHighlighter codeHighlighter;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.codeHighlighter,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isThinkingExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isUser = widget.message.type == MessageType.user;
    final theme = Theme.of(context);
    final bubbleAlignment =
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme
            .surfaceContainerHighest; // Or theme.colorScheme.surfaceVariant;
    final textColorOnBubble = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    Widget avatarImage;
    try {
      avatarImage = Image.asset(
        'assets/AstraPfP.png', // Ensure this path is correct and asset is in pubspec.yaml
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(
              isUser ? Icons.person_outline : Icons.hub_outlined,
              size: 20,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          );
        },
      );
    } catch (e) {
      print("Error loading avatar asset: $e");
      avatarImage = CircleAvatar(
        radius: 18,
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          isUser ? Icons.person_outline : Icons.hub_outlined,
          size: 20,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      );
    }
    final avatar = ClipOval(child: avatarImage);

    // Stylesheet for the main message body
    final mainMarkdownStyleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyMedium?.copyWith(
        color: textColorOnBubble,
        fontSize: 15,
        height: 1.45,
      ),
      a: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: theme.colorScheme.primary,
      ),
      code: theme.textTheme.bodyMedium?.copyWith(
        color: widget.codeHighlighter.currentTheme['root']?.color ??
            textColorOnBubble,
        backgroundColor: widget
                .codeHighlighter.currentTheme['root']?.backgroundColor
                ?.withOpacity(0.1) ??
            textColorOnBubble.withOpacity(0.05),
        fontFamily: 'monospace',
        fontSize: 13.5,
        height: 1.4,
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: widget.codeHighlighter.rootBackgroundColor ??
            (theme.brightness == Brightness.dark
                ? const Color(0xFF2B2B2B)
                : const Color(0xFFF6F8FA)),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      h1: theme.textTheme.headlineSmall?.copyWith(
        color: textColorOnBubble,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        color: textColorOnBubble,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        color: textColorOnBubble,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      h4: theme.textTheme.titleSmall?.copyWith(
        color: textColorOnBubble,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      h5: theme.textTheme.bodyLarge?.copyWith(
        color: textColorOnBubble,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      h6: theme.textTheme.bodyMedium?.copyWith(
        color: textColorOnBubble,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      em: theme.textTheme.bodyMedium?.copyWith(
        color: textColorOnBubble,
        fontStyle: FontStyle.italic,
      ),
      strong: theme.textTheme.bodyMedium?.copyWith(
        color: textColorOnBubble,
        fontWeight: FontWeight.bold,
      ),
      del: theme.textTheme.bodyMedium?.copyWith(
        color: textColorOnBubble,
        decoration: TextDecoration.lineThrough,
      ),
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: textColorOnBubble.withOpacity(0.9),
      ),
      blockquoteDecoration: BoxDecoration(
        color: bubbleColor.withOpacity(0.5),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.7),
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.all(10),
      listBullet: theme.textTheme.bodyMedium?.copyWith(
        color: textColorOnBubble,
      ),
      listIndent: 20,
      tableHead: const TextStyle(fontWeight: FontWeight.w600),
      tableBody: theme.textTheme.bodyMedium?.copyWith(color: textColorOnBubble),
      tableBorder: TableBorder.all(
        color: theme.dividerColor.withOpacity(0.5),
        width: 1,
      ),
      tableHeadAlign: TextAlign.center,
      tableColumnWidth: const IntrinsicColumnWidth(),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 1.0,
            color: theme.dividerColor.withOpacity(0.5),
          ),
        ),
      ),
    );

    // Stylesheet specifically for the thinking text
    final thinkingMarkdownStyleSheet = MarkdownStyleSheet.fromTheme(
      theme,
    ).copyWith(
      p: theme.textTheme.bodySmall?.copyWith(
        fontStyle: FontStyle.italic,
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.85),
        height: 1.3,
      ),
      code: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: theme.colorScheme.onSurface.withOpacity(0.05),
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.85),
        fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) *
            0.95, // Slightly smaller
      ),
      codeblockDecoration: BoxDecoration(
        // Simpler decoration for thoughts
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
      codeblockPadding: const EdgeInsets.all(8),
      listBullet: theme.textTheme.bodySmall?.copyWith(
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.85),
      ),
      // Inherit other styles or define minimally as needed for thoughts
    );

    Widget thinkingWidget = const SizedBox.shrink();
    if (!isUser &&
        widget.message.thinkingText != null &&
        widget.message.thinkingText!.isNotEmpty &&
        !(widget.message.text.trim() == '...' && !isUser)) {
      // Don't show for "..." placeholder
      thinkingWidget = Padding(
        padding: EdgeInsets.only(
          // Align with the main bubble content, considering avatar
          left: !isUser ? (36.0 + 8.0) : 0, // Avatar width (36) + padding (8)
          right:
              0, // No right padding needed typically for left-aligned thoughts
          bottom: 8.0, // Space between thought and main bubble below it
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  setState(() {
                    _isThinkingExpanded = !_isThinkingExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2.0,
                    horizontal: 4.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Thought: ",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.85,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isThinkingExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.75,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isThinkingExpanded)
              Container(
                // Container to give padding and slight visual distinction if needed
                padding: const EdgeInsets.only(
                  top: 4.0,
                  left: 8.0,
                  right: 8.0,
                ), // Indent actual thought
                width: double
                    .infinity, // Allow MarkdownBody to take available width
                child: MarkdownBody(
                  data: widget.message.thinkingText!,
                  selectable: true,
                  styleSheet: thinkingMarkdownStyleSheet,
                  // Optionally, for thoughts, you might use a more basic extension set
                  // extensionSet: md.ExtensionSet.commonMark,
                ),
              )
            else if (widget.message.thinkingText!.length >
                60) // Show snippet if collapsed & long
              Padding(
                padding: const EdgeInsets.only(top: 2.0, left: 8.0, right: 8.0),
                child: Text(
                  "${widget.message.thinkingText!.substring(0, 60)}...",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        crossAxisAlignment: bubbleAlignment,
        children: [
          // THOUGHT WIDGET MOVED HERE (ABOVE MAIN MESSAGE)
          if (!isUser) thinkingWidget,

          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 2.0),
                  child: avatar,
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18.0),
                      topRight: const Radius.circular(18.0),
                      bottomLeft: Radius.circular(isUser ? 18.0 : 4.0),
                      bottomRight: Radius.circular(isUser ? 4.0 : 18.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  child: widget.message.text.trim() == '...' && !isUser
                      ? const _LoadingDots()
                      : isUser
                          ? SelectableText(
                              widget.message.text,
                              style: TextStyle(
                                color: textColorOnBubble,
                                fontSize: 15,
                                height: 1.45,
                              ),
                            )
                          : MarkdownBody(
                              data: widget.message.text,
                              selectable: true,
                              syntaxHighlighter: widget.codeHighlighter,
                              extensionSet: md.ExtensionSet(
                                // Combined ExtensionSet for main answer
                                [
                                  ...md.ExtensionSet.gitHubWeb.blockSyntaxes,
                                  LatexBlockSyntax(),
                                ],
                                [
                                  ...md.ExtensionSet.gitHubWeb.inlineSyntaxes,
                                  LatexInlineSyntax(),
                                ],
                              ),
                              styleSheet: mainMarkdownStyleSheet,
                              onTapLink: (text, href, title) {
                                print("Link tapped: $href");
                                // if (href != null) {
                                //   final uri = Uri.tryParse(href);
                                //   if (uri != null /* && await canLaunchUrl(uri) */) {
                                //     // await launchUrl(uri);
                                //     print("Would launch: $uri");
                                //   } else {
                                //     print('Could not parse or launch $href');
                                //   }
                                // }
                              },
                            ),
                ),
              ),
              if (isUser)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                  child: avatar,
                ),
            ],
          ),
          // Original position of thinkingWidget removed
        ],
      ),
    );
  }
}

// _LoadingDots widget (ensure this is defined in this file or correctly imported)
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dot1Opacity;
  late Animation<double> _dot2Opacity;
  late Animation<double> _dot3Opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _dot1Opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    _dot2Opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );
    _dot3Opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(_dot1Opacity),
          _buildDot(_dot2Opacity),
          _buildDot(_dot3Opacity),
        ],
      ),
    );
  }
}
