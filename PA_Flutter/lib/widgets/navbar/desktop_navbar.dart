// Suggested path: lib/features/navbar/desktop_navbar.dart
import 'package:flutter/material.dart';
import 'package:projectastra/theme/app_colors.dart'; // Import AppColors

// Assuming AppRoutes is defined and imported if you use it for the home tab ID
// For example: import 'package:projectastra/routes/app_routes.dart';

class DesktopNavbar extends StatelessWidget {
  final VoidCallback onChatToggle;
  final VoidCallback onAppLauncherPressed;
  final String activeTab;
  final List<String> openTabs; // New: List of open tabs
  final List<String> pinnedTabs; // Renamed from 'tabs' to be more descriptive
  final void Function(String tabId) onTabSelected;
  final void Function(String tabId)
      onTabClosed; // New: Callback for closing a tab
  final void Function(String tabId)
      onTabPinned; // New: Callback for pinning a tab
  final VoidCallback?
      onProfilePressed; // Callback for when profile icon is pressed
  final void Function(String tabId)
      onRestoreTab; // New: Callback for restoring a minimized tab
  final VoidCallback? onProfilePicturePressed; // New: Callback for changing profile picture

  // Default list of tabs if none are provided from AppShell.
  // In a real app, this list would likely be managed by AppShell's state.
  static const List<String> _defaultPinnedTabs = ['Contacts', 'Help'];

  const DesktopNavbar({
    super.key,
    required this.onChatToggle,
    required this.onAppLauncherPressed,
    required this.activeTab,
    required this.openTabs,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onTabPinned,
    required this.onRestoreTab,
    this.pinnedTabs =
        _defaultPinnedTabs, // Use the default if no specific pinned tabs are passed
    this.onProfilePressed,
    this.onProfilePicturePressed, // Initialize the new callback
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Define a constant for the Home tab identifier for clarity
    const String homeTabId = 'Home'; // Or AppRoutes.home if you have it defined

    return Container(
      height: kToolbarHeight, // Standard toolbar height
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.02 > 24 ? width * 0.02 : 24,
      ), // Ensure min padding
      decoration: BoxDecoration(
        color: AppColors.darkBackground, // Use the new dark background color
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ), // Softer shadow
        ],
      ),
      child: Row(
        children: [
          // Left: Logo & Title (Clickable to go to Home)
          Row(
            children: [
              Image.asset(
                'assets/AstriumLogo.png', // Updated logo path
                width: 48, // Much bigger size
                height: 48,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if logo doesn't load
                  return const Icon(
                    Icons.blur_on,
                    size: 24,
                    color: Colors.lightBlueAccent,
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Display the pinned tabs as icons
                for (final tabId in pinnedTabs)
                  _PinnedTabItem(
                    icon: _getIconForTab(tabId), // Helper to get icon for tab
                    isActive: activeTab == tabId,
                    onTap: () => onTabSelected(tabId),
                    onRestore: () => onRestoreTab(tabId),
                  ),
                const SizedBox(width: 8),
                // Display the open (unpinned) tabs
                for (final tabId
                    in openTabs.where((t) => !pinnedTabs.contains(t)))
                  _OpenTabItem(
                    label: tabId,
                    isActive: activeTab == tabId,
                    onTap: () => onTabSelected(tabId),
                    onClose: () => onTabClosed(tabId),
                    onPin: () => onTabPinned(tabId),
                    // FIX: Added the missing 'onRestore' parameter
                    onRestore: () => onRestoreTab(tabId),
                  ),
              ],
            ),
          ),

          // Right: Chat, Menu, Profile
          Row(
            children: [
              Tooltip(
                message: 'App Launcher',
                child: IconButton(
                  icon: const Icon(Icons.apps),
                  color: Colors.white,
                  onPressed: onAppLauncherPressed,
                ),
              ),
              const SizedBox(width: 4), // Spacing between icons
              Tooltip(
                message: 'Open Chat',
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  color: Colors.white,
                  onPressed: onChatToggle,
                ),
              ),
              ],
          ),
        ],
      ),
    );
  }
}

// Helper function to get an icon for a given tab ID
IconData _getIconForTab(String tabId) {
  switch (tabId) {
    case 'Home':
      return Icons.home_rounded;
    case 'Contacts':
      return Icons.contacts_rounded;
    case 'Help':
      return Icons.help_outline_rounded;
    case 'Search':
      return Icons.search;
    case 'Docs':
      return Icons.article_outlined;
    case 'Code':
      return Icons.code;
    case 'Finance':
      return Icons.attach_money;
    case 'Email':
      return Icons.email_outlined;
    case 'Calendar':
      return Icons.calendar_today_outlined;
    default:
      return Icons.tab;
  }
}

class _PinnedTabItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRestore; // New: Callback for restoring

  const _PinnedTabItem({
    required this.icon,
    this.isActive = false,
    required this.onTap,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open', // You can make this dynamic based on the tab
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: isActive
              ? onTap
              : onRestore, // Restore if inactive, select if active
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isActive ? Colors.blue.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.blue : Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenTabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onPin;
  final VoidCallback onRestore; // New: Callback for restoring

  const _OpenTabItem({
    required this.label,
    this.isActive = false,
    required this.onTap,
    required this.onClose,
    required this.onPin,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.surface.withOpacity(0.5);

    return GestureDetector(
      onTap:
          isActive ? onTap : onRestore, // Restore if inactive, select if active
      onSecondaryTapUp: (details) {
        final RenderBox overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        showMenu(
          context: context,
          position: RelativeRect.fromRect(
            details.globalPosition &
                const Size(40, 40), // smaller rect, the touch area
            Offset.zero & overlay.size, // Bigger rect, the entire screen
          ),
          items: [
            const PopupMenuItem(
              value: 'pin',
              child: Text('Pin Tab'),
            ),
          ],
        ).then((value) {
          if (value == 'pin') {
            onPin();
          }
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(top: 12, right: 2, left: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: ShapeDecoration(
            color: isActive ? activeColor : inactiveColor,
            shape: _ChromeTabBorder(),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                iconSize: 14,
                color: isActive
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                onPressed: onClose,
                tooltip: 'Close Tab',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChromeTabBorder extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const radius = 8.0;
    return Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top + radius)
      ..arcToPoint(
        Offset(rect.left + radius, rect.top),
        radius: const Radius.circular(radius),
        clockwise: true,
      )
      ..lineTo(rect.right - radius, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + radius),
        radius: const Radius.circular(radius),
        clockwise: true,
      )
      ..lineTo(rect.right, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class _NavItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Colors.lightBlueAccent;
    final Color hoverColor = Colors.blueAccent.withOpacity(0.8);
    final Color defaultColor = Colors.white.withOpacity(0.85);

    final Color textColor = widget.isActive
        ? activeColor
        : _hovering
            ? hoverColor
            : defaultColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 4,
          ), // Margin between nav items
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ), // Padding within nav items
          decoration: BoxDecoration(
            // Underline for active tab
            border: widget.isActive
                ? const Border(
                    bottom: BorderSide(
                      width: 2.5, // Slightly thicker underline
                      color: activeColor,
                    ),
                  )
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: textColor,
              fontSize: 15, // Slightly larger font
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}