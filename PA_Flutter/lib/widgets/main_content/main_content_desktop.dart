import 'package:flutter/material.dart';
import 'package:projectastra/services/auth_service.dart';
import 'dart:math' as math;

// A simple model for a window
class DesktopWindow {
  final String id;
  final Widget content;
  Rect position;
  bool isVisible;
  bool isFocused;
  List<DesktopWindow> linkedWindows = [];

  DesktopWindow({
    required this.id,
    required this.content,
    required this.position,
    this.isVisible = true,
    this.isFocused = false,
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
  final List<DesktopWindow> _windows = [];
  // A map to store the actual widgets for each ID
  final Map<String, Widget> _widgetMap = {};
  final double _gridSize = 20.0;

  @override
  void initState() {
    super.initState();
    // Initialize the widget map
    _widgetMap.addAll({
      'Search': const Center(child: Text("Search Page")),
      'Docs': const Center(child: Text("Docs Page")),
      'Code': const Center(child: Text("Code Page")),
      'Finance': const Center(child: Text("Finance Page")),
      'Email': const Center(child: Text("Email Page")),
      'Calendar': const Center(child: Text("Calendar Page")),
      'Chat': const Center(child: Text("Chat Page")),
    });

    if (widget.initialActiveWidgetId != AppRoutes.home) {
      openWidgetById(widget.initialActiveWidgetId);
    }
  }

  void openWidgetById(String id) {
    // Check if a window with this ID is already open
    if (_windows.any((w) => w.id == id)) {
      // If it is, bring it to the front and focus it
      setState(() {
        final window = _windows.firstWhere((w) => w.id == id);
        _windows.remove(window);
        _windows.add(window);
        _windows.forEach((w) => w.isFocused = (w.id == id));
      });
      return;
    }

    // If not, create a new window
    final widget = _widgetMap[id];
    if (widget != null) {
      setState(() {
        _windows.forEach((w) => w.isFocused = false);
        _windows.add(DesktopWindow(
          id: id,
          content: widget,
          position: Rect.fromLTWH(
            _windows.length * 30.0, // Staggered initial position
            _windows.length * 30.0,
            400,
            300,
          ),
          isFocused: true,
        ));
        _resolveOverlaps();
      });
    }
  }

  void toggleWidgetById(String id) {
    final window = _windows.firstWhere((w) => w.id == id, orElse: () => null);
    if (window != null) {
      setState(() {
        window.isVisible = !window.isVisible;
      });
    } else {
      openWidgetById(id);
    }
  }

  void restoreWidget(String tabId) {
    final window = _windows.firstWhere((w) => w.id == tabId, orElse: () => null);
    if (window != null) {
      setState(() {
        window.isVisible = true;
      });
    }
  }

  void _toggleLink(DesktopWindow window) {
    final other = _findAdjacentWindow(window);
    if (other != null) {
      setState(() {
        if (window.linkedWindows.contains(other)) {
          window.linkedWindows.remove(other);
          other.linkedWindows.remove(window);
        } else {
          window.linkedWindows.add(other);
          other.linkedWindows.add(window);
        }
      });
    }
  }

  DesktopWindow? _findAdjacentWindow(DesktopWindow window) {
    DesktopWindow? closest;
    double minDistance = double.infinity;

    for (var other in _windows) {
      if (other == window) continue;

      final distance = _calculateDistance(window.position.center, other.position.center);
      if (distance < minDistance) {
        minDistance = distance;
        closest = other;
      }
    }
    return closest;
  }

  double _calculateDistance(Offset p1, Offset p2) {
    return (p1 - p2).distance;
  }

  void _resolveOverlaps() {
    bool changed = true;
    while (changed) {
      changed = false;
      for (int i = 0; i < _windows.length; i++) {
        for (int j = i + 1; j < _windows.length; j++) {
          final window1 = _windows[i];
          final window2 = _windows[j];
          if (window1.position.overlaps(window2.position)) {
            setState(() {
              window2.position = window2.position.translate(window1.position.width, 0);
            });
            changed = true;
          }
        }
      }
    }
  }

  void _snapToGrid(DesktopWindow window) {
    setState(() {
      final left = (window.position.left / _gridSize).round() * _gridSize;
      final top = (window.position.top / _gridSize).round() * _gridSize;
      final width = (window.position.width / _gridSize).round() * _gridSize;
      final height = (window.position.height / _gridSize).round() * _gridSize;
      window.position = Rect.fromLTWH(left, top, width, height);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: WindowLinkPainter(_windows),
          child: Container(),
        ),
        ..._windows.where((w) => w.isVisible).map((window) {
          return Positioned(
            left: window.position.left,
            top: window.position.top,
            width: window.position.width,
            height: window.position.height,
            child: GestureDetector(
              onPanStart: (_) {
                setState(() {
                  _windows.remove(window);
                  _windows.add(window);
                  _windows.forEach((w) => w.isFocused = (w.id == window.id));
                });
              },
              onPanEnd: (_) {
                _snapToGrid(window);
                _resolveOverlaps();
              },
              onPanUpdate: (details) {
                setState(() {
                  final newPosition = window.position.translate(
                    details.delta.dx,
                    details.delta.dy,
                  );
                  window.position = newPosition;

                  for (var linkedWindow in window.linkedWindows) {
                    linkedWindow.position = linkedWindow.position.translate(
                      details.delta.dx,
                      details.delta.dy,
                    );
                  }
                });
              },
              child: Focus(
                onFocusChange: (hasFocus) {
                  setState(() {
                    window.isFocused = hasFocus;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: window.isFocused ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                    color: Theme.of(context).cardColor,
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 30,
                        color: Colors.grey[300],
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.link,
                                color: window.linkedWindows.isNotEmpty
                                    ? Colors.blue
                                    : Colors.black,
                              ),
                              onPressed: () => _toggleLink(window),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(window.id),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _windows.remove(window);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: window.content,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onPanEnd: (_) {
                            _snapToGrid(window);
                            _resolveOverlaps();
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              final newWidth = math.max(100.0, window.position.width + details.delta.dx);
                              final newHeight = math.max(100.0, window.position.height + details.delta.dy);

                              final widthRatio = newWidth / window.position.width;
                              final heightRatio = newHeight / window.position.height;

                              window.position = Rect.fromLTWH(
                                window.position.left,
                                window.position.top,
                                newWidth,
                                newHeight,
                              );

                              for (var linkedWindow in window.linkedWindows) {
                                final newLinkedWidth = linkedWindow.position.width * widthRatio;
                                final newLinkedHeight = linkedWindow.position.height * heightRatio;
                                linkedWindow.position = Rect.fromLTWH(
                                  linkedWindow.position.left,
                                  linkedWindow.position.top,
                                  newLinkedWidth,
                                  newLinkedHeight,
                                );
                              }
                            });
                          },
                          child: const Icon(
                            Icons.aspect_ratio,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class WindowLinkPainter extends CustomPainter {
  final List<DesktopWindow> windows;

  WindowLinkPainter(this.windows);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;

    for (var window in windows) {
      for (var linkedWindow in window.linkedWindows) {
        canvas.drawLine(
          window.position.center,
          linkedWindow.position.center,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}


// Dummy AppRoutes class for compilation
class AppRoutes {
    static const String home = 'home';
    static const String desktopChat = 'Chat';
}