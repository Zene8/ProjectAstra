import 'package:flutter/material.dart';
import 'package:projectastra/widgets/chat/chat_panel.dart'; // Import ChatPanel
import 'package:projectastra/routes/app_routes.dart'; // Import your routes
import 'package:projectastra/widgets/pages/user_settings.dart';
// Assuming AuthService is in this path, adjust if necessary
import 'package:projectastra/services/auth_service.dart';

import 'package:projectastra/widgets/pages/calendar_page.dart';
import 'package:projectastra/widgets/pages/email_page.dart';
import 'package:projectastra/widgets/pages/finance_page.dart';
import 'package:projectastra/widgets/pages/code_page.dart';
import 'package:projectastra/widgets/pages/docs_page.dart';
import 'package:projectastra/widgets/pages/search_page.dart';

// Helper to get widget based on ID, now accepts AuthService
Widget _getDesktopWidgetById(
  String id, {
  required AuthService authService,
}) {
  switch (id) {
    case AppRoutes.home:
      return Container(
        color: Colors.blueGrey[700],
        child: const Center(
          child: Text(
            "Desktop Home Widget",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    case AppRoutes.desktopChat:
      // ChatPanel is now a regular window, onClose is handled by ManagedWindow's close button
      return ChatPanel(
        isMobile: false,
        // onClose: onCloseCallback, // This will be handled by the ManagedWindow's title bar
        backgroundColor: Colors.grey[800],
      );
    case AppRoutes.contacts:
      return Container(
        color: Colors.teal[700],
        child: const Center(
          child: Text(
            "Desktop Contacts Widget",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    case AppRoutes.help:
      return Container(
        color: Colors.indigo[700],
        child: const Center(
          child: Text(
            "Desktop Help Widget",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    case AppRoutes.userSettings:
      return UserSettingsPage(authService: authService);
    case 'Search':
      return const SearchPage();
    case 'Docs':
      return const DocsPage();
    case 'Code':
      return const CodePage();
    case 'Finance':
      return const FinancePage();
    case 'Email':
      return const EmailPage();
    case 'Calendar':
      return const CalendarPage();
    default:
      return Container(
        color: Colors.red[700],
        child: Center(
          child: Text(
            "Unknown Widget: $id",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
  }
}

class ManagedWindow {
  final String id;
  Widget content;
  Rect position;
  // bool isFloating; // May not be needed if all are "floating"
  int zOrder;
  final Key key = UniqueKey();
  Size minSize; // Minimum size for the window
  Size? maxSize; // Optional maximum size

  ManagedWindow({
    required this.id,
    required this.content,
    required this.position, // Position will be calculated initially
    // this.isFloating = true, // All windows are effectively floating now
    this.zOrder = 0,
    this.minSize = const Size(200, 150), // Default minimum size
    this.maxSize,
  });
}

class MainContentDesktop extends StatefulWidget {
  final String initialActiveWidgetId;
  final AuthService authService;

  const MainContentDesktop({
    super.key,
    required this.initialActiveWidgetId,
    required this.authService,
  });

  @override
  State<MainContentDesktop> createState() => MainContentDesktopState();
}

class MainContentDesktopState extends State<MainContentDesktop> {
  final List<ManagedWindow> _openWindows = [];
  int _highestZOrder = 0;
  // String? _primaryWidgetId; // May not be needed if focus is just z-order based
  BoxConstraints _currentConstraints = const BoxConstraints();
  static const double titleBarHeight = 30.0;
  static const double resizeHandleSize = 16.0;

  @override
  void initState() {
    super.initState();
    // _primaryWidgetId = widget.initialActiveWidgetId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensureInitialWidgetOpened(widget.initialActiveWidgetId);
      }
    });
  }

  void _ensureInitialWidgetOpened(String id) {
    if (_openWindows.indexWhere((w) => w.id == id) == -1) {
      openWidgetById(id);
    }
  }

  void openWidgetById(String id) {
    _openOrFocusWidget(id);
  }

  void toggleWidgetById(String id) {
    final existingWindowIndex = _openWindows.indexWhere((w) => w.id == id);
    if (existingWindowIndex != -1) {
      _closeWidget(id);
    } else {
      _openOrFocusWidget(id);
    }
  }

  Rect _calculateInitialPosition(String id, Size newWindowMinSize) {
    if (!_currentConstraints.hasBoundedWidth ||
        !_currentConstraints.hasBoundedHeight) {
      // Fallback if constraints aren't ready (should be rare)
      return Rect.fromLTWH(
          50, 50, newWindowMinSize.width, newWindowMinSize.height);
    }
    // Cascade new windows slightly
    double initialX = 50.0 + (_openWindows.length % 5) * 30;
    double initialY = 50.0 + (_openWindows.length % 5) * 30;

    // Ensure it's within bounds
    initialX = initialX.clamp(
        0, _currentConstraints.maxWidth - newWindowMinSize.width);
    initialY = initialY.clamp(
        0, _currentConstraints.maxHeight - newWindowMinSize.height);

    return Rect.fromLTWH(
        initialX, initialY, newWindowMinSize.width, newWindowMinSize.height);
  }

  void _openOrFocusWidget(String id) {
    if (!mounted) return;

    final existingWindowIndex = _openWindows.indexWhere((w) => w.id == id);
    if (existingWindowIndex != -1) {
      _bringToFront(id); // Just bring to front if already open
      return;
    }

    if (!_currentConstraints.hasBoundedWidth ||
        !_currentConstraints.hasBoundedHeight) {
      print(
          "MainContentDesktop: Constraints not available. Deferring widget opening.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openOrFocusWidget(id);
      });
      return;
    }

    final newContent = _getDesktopWidgetById(
      id,
      // onCloseCallback is now handled by the window's own close button
      authService: widget.authService,
    );

    // Define a default/minimum size for new windows, can be specific per widget ID
    Size minSize = const Size(300, 200);
    if (id == AppRoutes.desktopChat) {
      minSize = const Size(250, 300);
    }

    setState(() {
      _highestZOrder++;
      final newWindow = ManagedWindow(
        id: id,
        content: newContent,
        position: _calculateInitialPosition(id, minSize),
        zOrder: _highestZOrder,
        minSize: minSize,
      );
      _openWindows.add(newWindow);
      _openWindows.sort((a, b) => a.zOrder.compareTo(b.zOrder));
      // _primaryWidgetId = id; // Focus is primarily visual (z-order)
    });
  }

  void _closeWidget(String id) {
    if (!mounted) return;
    setState(() {
      _openWindows.removeWhere((w) => w.id == id);
      // if (_primaryWidgetId == id) {
      //   _primaryWidgetId =
      //       _openWindows.isNotEmpty ? _openWindows.last.id : null;
      // }
      // No need to recalculate layout here, just remove the window
    });
  }

  void _bringToFront(String id) {
    if (!mounted) return;
    final index = _openWindows.indexWhere((w) => w.id == id);
    if (index != -1) {
      setState(() {
        final window = _openWindows[index];
        if (window.zOrder < _highestZOrder) {
          // Only update if not already at front
          window.zOrder = ++_highestZOrder;
          _openWindows.sort((a, b) => a.zOrder.compareTo(b.zOrder));
        }
        // _primaryWidgetId = id;
      });
    }
  }

  void _updateWindowPosition(String id, DragUpdateDetails details) {
    if (!mounted) return;
    final index = _openWindows.indexWhere((w) => w.id == id);
    if (index != -1) {
      setState(() {
        final window = _openWindows[index];
        double newLeft = window.position.left + details.delta.dx;
        double newTop = window.position.top + details.delta.dy;

        // Boundary checks
        newLeft = newLeft.clamp(
            0, _currentConstraints.maxWidth - window.position.width);
        newTop = newTop.clamp(
            0, _currentConstraints.maxHeight - window.position.height);

        window.position = Rect.fromLTWH(
            newLeft, newTop, window.position.width, window.position.height);
      });
    }
  }

  void _updateWindowSize(String id, DragUpdateDetails details) {
    if (!mounted) return;
    final index = _openWindows.indexWhere((w) => w.id == id);
    if (index != -1) {
      setState(() {
        final window = _openWindows[index];
        double newWidth = window.position.width + details.delta.dx;
        double newHeight = window.position.height + details.delta.dy;

        // Apply min/max constraints
        newWidth = newWidth.clamp(
            window.minSize.width, window.maxSize?.width ?? double.infinity);
        newHeight = newHeight.clamp(
            window.minSize.height, window.maxSize?.height ?? double.infinity);

        // Boundary checks for resizing
        if (window.position.left + newWidth > _currentConstraints.maxWidth) {
          newWidth = _currentConstraints.maxWidth - window.position.left;
        }
        if (window.position.top + newHeight > _currentConstraints.maxHeight) {
          newHeight = _currentConstraints.maxHeight - window.position.top;
        }

        // Ensure width/height don't go below minSize due to boundary clamp
        newWidth =
            newWidth < window.minSize.width ? window.minSize.width : newWidth;
        newHeight = newHeight < window.minSize.height
            ? window.minSize.height
            : newHeight;

        window.position = Rect.fromLTWH(
            window.position.left, window.position.top, newWidth, newHeight);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (_currentConstraints != constraints &&
            constraints.hasBoundedWidth &&
            constraints.hasBoundedHeight) {
          // If constraints change, we might want to adjust window positions/sizes
          // to ensure they are still valid. For now, we'll rely on clamping.
          _currentConstraints = constraints;
          // Optionally, iterate through _openWindows and clamp their positions/sizes
          // if the overall container size has shrunk.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              bool needsRebuild = false;
              for (var window in _openWindows) {
                double newLeft = window.position.left
                    .clamp(0, constraints.maxWidth - window.position.width);
                double newTop = window.position.top
                    .clamp(0, constraints.maxHeight - window.position.height);
                double newWidth = window.position.width.clamp(
                    window.minSize.width, constraints.maxWidth - newLeft);
                double newHeight = window.position.height.clamp(
                    window.minSize.height, constraints.maxHeight - newTop);

                if (window.position.left != newLeft ||
                    window.position.top != newTop ||
                    window.position.width != newWidth ||
                    window.position.height != newHeight) {
                  window.position =
                      Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
                  needsRebuild = true;
                }
              }
              if (needsRebuild) {
                setState(() {});
              }
            }
          });
        } else if (_currentConstraints.maxWidth == 0 &&
            constraints.hasBoundedWidth) {
          // First time constraints are available
          _currentConstraints = constraints;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                _openWindows.isEmpty &&
                widget.initialActiveWidgetId.isNotEmpty) {
              _ensureInitialWidgetOpened(widget.initialActiveWidgetId);
            }
          });
        }

        if (_openWindows.isEmpty) {
          return const Center(
            child: Text(
              "No windows open. Select an item from the top bar.",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ClipRect(
          child: Stack(
            children: _openWindows.map((window) {
              return Positioned(
                key: window.key,
                left: window.position.left,
                top: window.position.top,
                width: window.position.width
                    .clamp(window.minSize.width, double.infinity),
                height: window.position.height
                    .clamp(window.minSize.height, double.infinity),
                child: GestureDetector(
                  // To bring to front when any part of the window is tapped
                  onTapDown: (_) => _bringToFront(window.id),
                  child: Material(
                    elevation: (window.zOrder /
                            (_highestZOrder != 0 ? _highestZOrder : 1) *
                            8.0) +
                        2.0, // Increased max elevation for better distinction
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0)),
                    clipBehavior: Clip.antiAlias,
                    color: Theme.of(context)
                        .cardColor, // Use theme card color for window background
                    child: Column(
                      children: [
                        GestureDetector(
                          // Title bar for dragging
                          onPanDown: (_) => _bringToFront(window.id),
                          onPanUpdate: (details) =>
                              _updateWindowPosition(window.id, details),
                          child: Container(
                            height: titleBarHeight,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.8),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    window.id, // Display window ID
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.8),
                                  ),
                                  onPressed: () => _closeWidget(window.id),
                                  splashRadius: 18,
                                  tooltip: "Close ${window.id}",
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                            child: Stack(
                          children: [
                            window.content,
                            Positioned(
                              // Resize Handle
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onPanDown: (_) => _bringToFront(window.id),
                                onPanUpdate: (details) =>
                                    _updateWindowSize(window.id, details),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.resizeDownRight,
                                  child: Container(
                                    width: resizeHandleSize,
                                    height: resizeHandleSize,
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.3),
                                        borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8))),
                                    child: Icon(
                                      Icons
                                          .open_in_full, // Or a more specific resize icon
                                      size: resizeHandleSize * 0.6,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondary
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
