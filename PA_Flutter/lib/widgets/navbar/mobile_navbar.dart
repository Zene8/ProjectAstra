// Suggested path: projectastra/features/navbar/mobile_navbar.dart
import 'package:flutter/material.dart';
import 'package:projectastra/theme/app_colors.dart'; // Import AppColors

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected; // General tab selection callback
  final VoidCallback onChatPressed;
  final VoidCallback onHomePressed;
  final VoidCallback onSettingsPressed;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onChatPressed,
    required this.onHomePressed,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    const double iconSize = 24.0; // Standard icon size
    const Color activeColor =
        Colors.lightBlueAccent; // Color for selected/active items

    return BottomNavigationBar(
      backgroundColor: AppColors.darkBackground, // Use the new dark background color
      currentIndex: currentIndex,
      selectedItemColor: activeColor,
      unselectedItemColor: Colors.white70,
      showUnselectedLabels: false,
      showSelectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8.0, // Standard elevation

      onTap: (index) {
        if (index == 0) {
          onHomePressed(); // For 'Tabs' item
        } else if (index == 1) {
          onChatPressed(); // For 'Chat' item
        } else if (index == 2) {
          onSettingsPressed(); // For 'Profile' item
        } else {
          // Fallback, though with 3 items and specific handlers, this might not be strictly needed
          // unless onTabSelected has a more general purpose.
          onTabSelected(index);
        }
      },
      items: [
        // Index 0: Tabs/Home
        const BottomNavigationBarItem(
          icon: Icon(Icons.tab_outlined, size: iconSize),
          activeIcon: Icon(Icons.tab, size: iconSize),
          label: 'Tabs',
        ),
        // Index 1: Chat with Custom Logo
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/AstriumLogo.png', // Updated logo path
            width: iconSize * 1.2, // Slightly larger for a logo
            height: iconSize * 1.2,
            // Optionally apply a color filter if your logo is monochrome and needs tinting
            // color: Colors.white70, // This would tint the non-transparent parts
            errorBuilder: (context, error, stackTrace) {
              // Fallback if the asset fails to load
              return const Icon(
                Icons.chat_bubble_outline,
                size: iconSize,
                color: Colors.white70,
              );
            },
          ),
          activeIcon: Container(
            padding: const EdgeInsets.all(
              1.0,
            ), // Minimal padding for the border effect
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white, // Outline color when active
                width: 1.0, // Border width
              ),
              shape: BoxShape.circle, // Circular outline
            ),
            child: Image.asset(
              'assets/AstriumLogo.png', // Updated logo path
              width: iconSize * 1.2 -
                  4, // Image slightly smaller to fit within border
              height: iconSize * 1.2 - 4,
              // If your logo is single-color and you want it to take the active color when outlined:
              // color: activeColor,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if the asset fails to load
                return const Icon(
                  Icons.chat_bubble,
                  size: iconSize,
                  color: activeColor,
                );
              },
            ),
          ),
          label: 'Chat',
        ),
        // Index 2: Profile/Settings
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_outlined, size: iconSize),
          activeIcon: Icon(Icons.account_circle, size: iconSize),
          label: 'Profile',
        ),
      ],
    );
  }
}
