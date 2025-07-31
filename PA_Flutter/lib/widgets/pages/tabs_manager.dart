// Suggested path: lib/features/pages/tabs_manager.dart
import 'package:flutter/material.dart';

// Data class for a single tab
class TabData {
  final String id;
  final String title;
  final String preview;

  TabData({required this.id, required this.title, required this.preview});
}

// Widget for displaying the grid of open tabs
class TabsPage extends StatelessWidget {
  final List<TabData> tabs;
  final Function(String id) onSelectTab;
  final Function(String id) onCloseTab;

  const TabsPage({
    super.key,
    required this.tabs,
    required this.onSelectTab,
    required this.onCloseTab,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the number of columns in the grid based on screen width
    final crossAxisCount = MediaQuery.of(context).size.width > 600 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Tabs'),
        // You might want to customize the AppBar color to match your theme
        // backgroundColor: Colors.grey[850], // Example
      ),
      // Set a background color for the body if needed, or it will inherit from the theme
      // backgroundColor: Colors.grey[700], // Example
      body: tabs.isEmpty
          ? Center(
              child: Text(
                'No open tabs.',
                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(
                16,
              ), // Increased padding around the grid
              itemCount: tabs.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16, // Increased spacing
                crossAxisSpacing: 16, // Increased spacing
                childAspectRatio: 4 / 3, // Adjust as needed for your content
              ),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                return GestureDetector(
                  onTap: () => onSelectTab(tab.id),
                  onLongPress: () {
                    // Consider a more explicit close button for better UX
                    // Example: show a confirmation dialog before closing
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Close Tab?'),
                        content: Text(
                          'Do you want to close "${tab.title}"?',
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                          ),
                          TextButton(
                            child: const Text(
                              'Close',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              onCloseTab(tab.id);
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // You might want to set a specific color for the cards
                    // color: Colors.grey[800], // Example
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tab.title,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ), // Added bold
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              tab.preview,
                              maxLines: 5, // Adjusted max lines
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          // Optional: Add a more explicit close button on the card
                          // Align(
                          //   alignment: Alignment.topRight,
                          //   child: IconButton(
                          //     icon: Icon(Icons.close, size: 20),
                          //     onPressed: () => onCloseTab(tab.id),
                          //     padding: EdgeInsets.zero,
                          //     constraints: BoxConstraints(),
                          //   ),
                          // )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
