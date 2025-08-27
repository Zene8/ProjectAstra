import 'package:flutter/material.dart';
import 'package:projectastra/services/auth_service.dart'; // Assuming this is needed

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
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('MainContentDesktop Placeholder'),
    );
  }
}