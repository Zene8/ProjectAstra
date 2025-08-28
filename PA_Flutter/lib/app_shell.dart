import 'package:flutter/material.dart';
// ===== VERIFY YOUR IMPORT PATHS =====
import 'package:projectastra/services/auth_service.dart'; // Your AuthService
import 'package:projectastra/services/pfp_service.dart'; // Import PfpService
import 'package:projectastra/widgets/main_content/main_content_desktop.dart';
import 'package:projectastra/widgets/navbar/desktop_navbar.dart';
import 'package:projectastra/widgets/navbar/mobile_navbar.dart';
import 'package:projectastra/widgets/pages/chat_page_mobile.dart';
import 'package:projectastra/widgets/pages/tabs_manager.dart';
import 'package:projectastra/widgets/pages/user_settings.dart';
import 'package:projectastra/widgets/pages/single_tab_page.dart';
import 'package:projectastra/routes/app_routes.dart';
// Import Provider if you're using it for AuthService
import 'package:provider/provider.dart';
import 'package:project_astra/services/application_context_notifier.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Desktop State
  String _activeDesktopContentId = AppRoutes.home;
  final List<String> _openTabs = [];
  final List<String> _pinnedTabs = [];

  // Mobile State
  int _currentMobilePageIndex = 0;
  final PageController _mobilePageController = PageController();
  late List<Widget> _mobilePages;

  final List<TabData> _sampleMobileTabs = [
    TabData(
        id: 'tab1',
        title: 'Mobile Tab 1',
        preview: 'Preview for mobile tab 1...'),
    TabData(
        id: 'tab2',
        title: 'Mobile Tab 2',
        preview: 'Preview for mobile tab 2...'),
  ];

  final GlobalKey<MainContentDesktopState> mainContentDesktopKey =
      GlobalKey<MainContentDesktopState>();

  late AuthService _authService;
  late PfpService _pfpService; // Instantiate PfpService
  bool _isAuthServiceInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAuthServiceInitialized) {
      try {
        _authService = Provider.of<AuthService>(context, listen: false);
        _pfpService = PfpService(); // Initialize PfpService
        print("AppShell: AuthService successfully obtained from Provider.");
        _initializeMobilePages();
        _isAuthServiceInitialized = true;
      } catch (e) {
        print(
            "AppShell: CRITICAL - Failed to obtain AuthService from Provider: $e. Falling back.");
        // Fallback for environments where Provider might not be set up (e.g. isolated widget tests)
        // In a real app, this path should ideally not be hit if Provider is set up correctly at the root.
        _authService =
            AuthService(); // Ensure this is a conscious decision if Provider is not used.
        _pfpService = PfpService(); // Initialize PfpService in fallback
        _initializeMobilePages();
        _isAuthServiceInitialized = true;
      }
    }
  }

  void _initializeMobilePages() {
    if (!_isAuthServiceInitialized) return;
    _mobilePages = [
      TabsPage(
        tabs: _sampleMobileTabs,
        onSelectTab: _handleMobileTabSelect,
        onCloseTab: _handleMobileTabClose,
      ),
      MobileChatPage(
        onNavigateAway: () {
          if (_mobilePageController.hasClients) {
            _mobilePageController.jumpToPage(0);
          }
        },
      ),
      UserSettingsPage(authService: _authService),
    ];
  }

  void _handleMobileTabSelect(String tabId) {
    TabData? selectedTabData;
    try {
      selectedTabData = _sampleMobileTabs.firstWhere((tab) => tab.id == tabId);
    } catch (e) {
      print("Error: Tab with ID '$tabId' not found.");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SingleTabPage(tabData: selectedTabData!),
      ),
    );
  }

  void _handleMobileTabClose(String id) {
    setState(() {
      _sampleMobileTabs.removeWhere((tab) => tab.id == id);
      if (_isAuthServiceInitialized) {
        _initializeMobilePages();
      }
    });
  }

  void _navigateToMobilePage(int index) {
    if (_currentMobilePageIndex != index && _mobilePageController.hasClients) {
      _mobilePageController.jumpToPage(index);
    }
  }

  void _onDesktopTabSelected(String tabId) {
    // UserSettings is no longer a tab here, it's a separate page
    if (tabId == AppRoutes.userSettings) {
      _handleDesktopProfilePressed();
      return;
    }
    setState(() {
      _activeDesktopContentId = tabId;
    });
    mainContentDesktopKey.currentState?.openWidgetById(tabId);
  }

  void _handleDesktopChatToggle() {
    if (!_openTabs.contains(AppRoutes.desktopChat)) {
      setState(() {
        _openTabs.add(AppRoutes.desktopChat);
      });
    }
    mainContentDesktopKey.currentState?.toggleWidgetById(AppRoutes.desktopChat);
  }

  void _handleTabClosed(String tabId) {
    setState(() {
      _openTabs.remove(tabId);
      if (_activeDesktopContentId == tabId) {
        _activeDesktopContentId =
            _openTabs.isNotEmpty ? _openTabs.last : AppRoutes.home;
      }
    });
  }

  void _handleTabPinned(String tabId) {
    setState(() {
      if (!_pinnedTabs.contains(tabId)) {
        _pinnedTabs.add(tabId);
      }
    });
  }

  void _handleDesktopProfilePressed() {
    // Navigate to UserSettingsPage as a full page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserSettingsPage(authService: _authService),
      ),
    );
    // We don't set _activeDesktopContentId to userSettings anymore,
    // as it's not a window within MainContentDesktop.
    // The MainContentDesktop can remain showing its last active window.
  }

  void _showAppLauncher() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Launcher'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 4,
            children: [
              _AppLauncherItem(
                  icon: Icons.search,
                  label: 'Search',
                  onTap: () => _openTab('Search')),
              _AppLauncherItem(
                  icon: Icons.article,
                  label: 'Docs',
                  onTap: () => _openTab('Docs')),
              _AppLauncherItem(
                  icon: Icons.code,
                  label: 'Code',
                  onTap: () => _openTab('Code')),
              _AppLauncherItem(
                  icon: Icons.attach_money,
                  label: 'Finance',
                  onTap: () => _openTab('Finance')),
              _AppLauncherItem(
                  icon: Icons.email,
                  label: 'Email',
                  onTap: () => _openTab('Email')),
              _AppLauncherItem(
                  icon: Icons.calendar_today,
                  label: 'Calendar',
                  onTap: () => _openTab('Calendar')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openTab(String tabId) {
    if (!_openTabs.contains(tabId)) {
      setState(() {
        _openTabs.add(tabId);
      });
    }
    _onDesktopTabSelected(tabId);
    Navigator.of(context).pop(); // Close the launcher
  }

  Future<void> _handleProfilePicturePressed() async {
    print("Attempting to change profile picture...");
    final pickedFile = await _pfpService.pickImage();
    if (pickedFile != null) {
      print("Image picked: ${pickedFile.path}");
      final photoUrl = await _pfpService.uploadProfilePicture(pickedFile);
      if (photoUrl != null) {
        print("Profile picture updated to: $photoUrl");
        // No need for setState here, as StreamBuilder in DesktopNavbar listens to authStateChanges
        // and will rebuild automatically when photoURL changes.
      } else {
        print("Failed to upload profile picture.");
      }
    } else {
      print("Image picking cancelled.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthServiceInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                  key: ValueKey("AppShellAuthServiceLoading")),
              SizedBox(height: 16),
              Text("Initializing services..."),
            ],
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isDesktopOrTablet = width >= 600;

    return ChangeNotifierProvider(
      create: (context) => ApplicationContextNotifier(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            if (isDesktopOrTablet)
              DesktopNavbar(
                activeTab: _activeDesktopContentId,
                openTabs: _openTabs,
                pinnedTabs: _pinnedTabs,
                onTabSelected: _onDesktopTabSelected,
                onTabClosed: _handleTabClosed,
                onTabPinned: _handleTabPinned,
                onChatToggle: _handleDesktopChatToggle,
                onProfilePressed: _handleDesktopProfilePressed,
                onAppLauncherPressed: _showAppLauncher,
                onRestoreTab: (tabId) =>
                    mainContentDesktopKey.currentState?.restoreWidget(tabId),
                onProfilePicturePressed:
                    _handleProfilePicturePressed, // Pass the new callback
              ),
            Expanded(
              child: isMobile
                  ? PageView(
                      controller: _mobilePageController,
                      children: _mobilePages,
                      onPageChanged: (index) {
                        if (_currentMobilePageIndex != index) {
                          setState(() {
                            _currentMobilePageIndex = index;
                          });
                        }
                      },
                    )
                  : MainContentDesktop(
                      key: mainContentDesktopKey,
                      initialActiveWidgetId: _activeDesktopContentId,
                      authService: _authService,
                    ),
            ),
            if (isMobile)
              BottomNavBar(
                currentIndex: _currentMobilePageIndex,
                onTabSelected: _navigateToMobilePage,
                onHomePressed: () => _navigateToMobilePage(0),
                onChatPressed: () => _navigateToMobilePage(1),
                onSettingsPressed: () => _navigateToMobilePage(2),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mobilePageController.dispose();
    super.dispose();
  }
}

class _AppLauncherItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AppLauncherItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
