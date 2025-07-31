// Suggested path: lib/features/navbar/desktop_navbar.dart
import 'package:flutter/material.dart';
// Assuming AppRoutes is defined and imported if you use it for the home tab ID
// For example: import 'package:projectastra/routes/app_routes.dart';

class DesktopNavbar extends StatelessWidget {
  final VoidCallback onChatToggle;
  final VoidCallback onAppLauncherPressed;
  final String activeTab;
  final List<String> openTabs; // New: List of open tabs
  final List<String> pinnedTabs; // Renamed from 'tabs' to be more descriptive
  final void Function(String tabId) onTabSelected;
  final void Function(String tabId) onTabClosed; // New: Callback for closing a tab
  final void Function(String tabId) onTabPinned; // New: Callback for pinning a tab
  final VoidCallback?
      onProfilePressed; // Callback for when profile icon is pressed

  // Default list of tabs if none are provided from AppShell.
  // In a real app, this list would likely be managed by AppShell's state.
  static const List<String> _defaultPinnedTabs = ['Home', 'Contacts', 'Help'];

  const DesktopNavbar({
    super.key,
    required this.onChatToggle,
    required this.onAppLauncherPressed,
    required this.activeTab,
    required this.openTabs,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onTabPinned,
    this.pinnedTabs = _defaultPinnedTabs, // Use the default if no specific pinned tabs are passed
    this.onProfilePressed,
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
        color: Colors.grey[850],
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
          GestureDetector(
            onTap: () => onTabSelected(homeTabId), // Navigate to Home
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  Image.asset(
                    'assets/AstraLogo.png', // Ensure this asset exists
                    width: 36, // Slightly adjusted size
                    height: 36,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if logo doesn't load
                      return const Icon(
                        Icons.blur_on,
                        size: 36,
                        color: Colors.lightBlueAccent,
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Astra AI",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlueAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 32),

          // Center: Pinned Tabs and Open Tabs
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
                  ),
                const VerticalDivider(width: 1, color: Colors.white24),
                const SizedBox(width: 8),
                // Display the open (unpinned) tabs
                for (final tabId in openTabs.where((t) => !pinnedTabs.contains(t)))
                  _OpenTabItem(
                    label: tabId,
                    isActive: activeTab == tabId,
                    onTap: () => onTabSelected(tabId),
                    onClose: () => onTabClosed(tabId),
                    onPin: () => onTabPinned(tabId),
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
              const SizedBox(width: 4), // Spacing between icons
              Tooltip(
                message: 'Menu', // Or "More Options"
                child: IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                  ), // Changed to more_vert for common menu
                  color: Colors.white,
                  onPressed: () {
                    // TODO: Implement a dropdown menu or sidebar toggle
                    print("DesktopNavbar: Menu/More Options pressed");
                  },
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Profile & Settings',
                child: GestureDetector(
                  onTap: onProfilePressed, // Call the new callback
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: CircleAvatar(
                      radius: 18, // Slightly adjusted size
                      // IMPORTANT: Ensure 'assets/UserProfile.png' exists
                      backgroundImage: const AssetImage(
                        'assets/UserProfile.png',
                      ),
                      onBackgroundImageError: (exception, stackTrace) {
                        // Fallback if profile image doesn't load
                        print("Error loading UserProfile.png: $exception");
                      }, // To ensure background is shown if image fails
                      backgroundColor: Colors.grey[700],
                      child: const Text(
                        '',
                      ), // Fallback background
                    ),
                  ),
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

  const _PinnedTabItem({
    required this.icon,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open', // You can make this dynamic based on the tab
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? Colors.blue.withOpacity(0.2) : Colors.transparent,
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

  const _OpenTabItem({
    required this.label,
    this.isActive = false,
    required this.onTap,
    required this.onClose,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.blue : Colors.white,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.push_pin_outlined),
                iconSize: 16,
                color: Colors.white,
                onPressed: onPin,
                tooltip: 'Pin Tab',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                iconSize: 16,
                color: Colors.white,
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

class _NavItem extends StatefulWidget {

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
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
            // Subtle background change on hover for non-active tabs
            // color: _hovering && !widget.isActive ? Colors.white.withOpacity(0.05) : Colors.transparent,
            // borderRadius: BorderRadius.circular(4), // Optional: if you want rounded hover background
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
