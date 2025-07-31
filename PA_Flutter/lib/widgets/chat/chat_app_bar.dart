import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNewChatPressed;
  final VoidCallback? onMoreOptionsPressed;
  final String title;
  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;

  const ChatAppBar({
    super.key,
    this.onMenuPressed,
    this.onNewChatPressed,
    this.onMoreOptionsPressed,
    this.title = "Astra AI",
    required this.backgroundColor,
    this.iconColor = Colors.white,
    this.titleColor = Colors.lightBlueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0.0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: onMenuPressed != null ? 56.0 : 16.0,
      leading: onMenuPressed != null
          ? IconButton(
              icon: Icon(Icons.menu, color: iconColor),
              onPressed: onMenuPressed,
              tooltip: 'Menu',
            )
          : const Padding(padding: EdgeInsets.only(left: 0.0)),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: <Widget>[
        if (onNewChatPressed != null)
          IconButton(
            icon: Icon(Icons.add_comment_outlined, color: iconColor),
            onPressed: onNewChatPressed,
            tooltip: 'New Chat',
          ),
        if (onMoreOptionsPressed != null)
          IconButton(
            icon: Icon(Icons.more_vert, color: iconColor),
            onPressed: onMoreOptionsPressed,
            tooltip: 'More options',
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
