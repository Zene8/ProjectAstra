import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChatInputBar extends StatelessWidget {
  // Changed to StatelessWidget
  final TextEditingController textController; // Receives the controller
  final VoidCallback onSend;
  final VoidCallback onVoice;
  final VoidCallback onAttach;
  final bool
      disabled; // Renamed from isSending for clarity if it means more than just "sending"

  const ChatInputBar({
    super.key,
    required this.textController, // Now required
    required this.onSend,
    required this.onVoice,
    required this.onAttach,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    // containerWidth will be determined within LayoutBuilder
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final bool hideSend =
            containerWidth < 345; // Thresholds can be adjusted
        final bool hideMic = containerWidth < 305; // Thresholds can be adjusted

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Dark blue-grey
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white38), // Softer border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment
                .end, // Align items to the bottom if TextField expands
            children: [
              _PlusMenu(
                moveMic: hideMic, // Mic moves into menu if space is tight
                onVoice: onVoice,
                onAttach: onAttach,
                disabled: disabled,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: textController, // Use the passed-in controller
                  // onChanged is not needed here if ChatPanel listens to the controller
                  onSubmitted: (_) {
                    // Keyboard submit action
                    if (!disabled) onSend();
                  },
                  enabled: !disabled,
                  maxLines: 100000000, // Allow multi-line input
                  minLines: 1,
                  textInputAction:
                      TextInputAction.send, // Show send button on keyboard
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    filled: true,
                    fillColor: const Color(0xFF101827), // Very dark blue
                    hintStyle: const TextStyle(
                      color: Color(0xFF758095),
                    ), // Muted grey
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10, // Adjust for comfortable typing
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // Consistent rounded corners
                      borderSide: const BorderSide(
                        color: Color(0xFF4B5563),
                      ), // Mid-grey
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFF4B5563)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      // Highlight when focused
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Colors.lightBlueAccent,
                        width: 1.5,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: const Color(0xFF4B5563).withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(disabled ? 0.6 : 1),
                    fontSize: 16,
                  ),
                  cursorColor: Colors.lightBlueAccent,
                ),
              ),
              const SizedBox(width: 8),
              if (!hideMic) // Mic button shown if enough space
                _CircleButton(
                  icon: LucideIcons.mic,
                  tooltip: 'Voice message',
                  onTap: onVoice,
                  disabled: disabled,
                ),
              if (!hideMic &&
                  !hideSend) // Add a little space if both are visible
                const SizedBox(width: 4),
              if (!hideSend) // Send button shown if enough space
                _CircleButton(
                  icon: LucideIcons.send,
                  tooltip: 'Send message',
                  onTap: onSend,
                  disabled: disabled,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool disabled;

  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedOpacity(
          opacity: disabled ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(
              10,
            ), // Adequate padding for tap target
            decoration: BoxDecoration(
              color: disabled
                  ? Colors.grey[600]
                  : const Color(0xFF1D5DFC), // Standard blue
              shape: BoxShape.circle,
              boxShadow: [
                if (!disabled) // No shadow if disabled
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Icon(
              icon,
              size: 22,
              color: Colors.white,
            ), // Slightly larger icon
          ),
        ),
      ),
    );
  }
}

class _PlusMenu extends StatelessWidget {
  final bool moveMic;
  final VoidCallback onVoice;
  final VoidCallback onAttach;
  final bool disabled;

  const _PlusMenu({
    required this.moveMic,
    required this.onVoice,
    required this.onAttach,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'mic') onVoice();
        if (value == 'file') onAttach();
      },
      enabled: !disabled,
      icon: Icon(
        LucideIcons.plusCircle, // Changed to plusCircle for better visual
        color: disabled ? Colors.grey[600] : Colors.white,
        size: 26,
      ),
      color: const Color(0xFF2A2D3E), // Dark popup background
      tooltip: 'More options',
      itemBuilder: (context) => [
        if (moveMic) // If mic button is hidden, show it in menu
          PopupMenuItem(
            value: 'mic',
            enabled: !disabled,
            child: const Row(
              children: [
                Icon(LucideIcons.mic, color: Colors.white),
                SizedBox(width: 8),
                Text('Voice Input', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'file',
          enabled: !disabled,
          child: const Row(
            children: [
              Icon(LucideIcons.paperclip, color: Colors.white),
              SizedBox(width: 8),
              Text('Attach File', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        // You can add more items here e.g. location, contact
      ],
    );
  }
}
