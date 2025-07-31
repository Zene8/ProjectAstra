import 'package:flutter/material.dart';
import 'package:projectastra/widgets/pages/tabs_manager.dart';

class SingleTabPage extends StatelessWidget {
  final TabData tabData;

  const SingleTabPage({super.key, required this.tabData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tabData.title),
        // The back button is automatically added by Navigator when pushing a route
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // In case content is long
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tabData.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              // For now, just displaying the preview text.
              // You can replace this with more complex widget structures
              // based on what your tab content actually is.
              Text(
                tabData.preview,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontSize: 16),
              ),
              // Add more widgets here to display the full content of the tab
            ],
          ),
        ),
      ),
    );
  }
}
