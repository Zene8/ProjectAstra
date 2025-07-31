// projectastra/features/home/presentation/home_page_mobile.dart
import 'package:flutter/material.dart';

class HomePageMobile extends StatelessWidget {
  const HomePageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with your actual mobile home page content
    // This could use a simplified version of your GridView or completely different layout
    return Scaffold(
      // appBar: AppBar(title: Text("Home Mobile")), // Optional if TopMobileBanner handles it
      body: Container(
        color: Colors.grey[800],
        padding: const EdgeInsets.all(8),
        child: GridView.builder(
          itemCount: 3, // Example
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1, // Full width tiles on mobile
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5, // Adjust as needed
          ),
          itemBuilder: (context, index) {
            return AppTile(
              title: 'App ${index + 1}',
              icon: Icons.apps,
              onTap: () {
                // Handle tile tap
                print('Tapped on App ${index + 1}');
              },
            );
          },
        ),
      ),
    );
  }
}

class AppTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const AppTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(leading: Icon(icon), title: Text(title), onTap: onTap),
    );
  }
}
