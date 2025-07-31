// lib/routing/app_routes.dart

class AppRoutes {
  // For AppShell's mobile page navigation and general identification
  static const String home =
      'Home'; // Used for desktop home, and mobile tabs page (index 0)
  static const String mobileChats =
      'MobileChats'; // Specific to mobile chat page if needed
  static const String profile =
      'Profile'; // Used for mobile profile page (index 2)

  // For desktop/tablet - widgets that can be opened in MainContentDesktop
  static const String desktopChat = 'DesktopChat';
  static const String contacts = 'Contacts'; // Used for desktop pinned tab
  static const String help = 'Help'; // Used for desktop pinned tab

  // Add this new route for user settings, used by desktop profile button
  static const String userSettings = 'UserSettings';

  // Add any other route names or identifiers your app uses
}
