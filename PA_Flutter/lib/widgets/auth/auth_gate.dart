// File: auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For User object

// ===== ADJUST YOUR IMPORT PATHS =====
// Ensure these paths correctly point to your files.
import 'package:projectastra/services/auth_service.dart'; // Your AuthService
import 'package:projectastra/widgets/auth/auth_modal.dart'; // Your AuthModal
import 'package:projectastra/app_shell.dart'; // Your main AppShell (or authenticated screen)
// ====================================

class AuthGate extends StatelessWidget {
  final AuthService authService;

  const AuthGate({
    super.key,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Handle connection states (e.g., waiting for the first auth state)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                key: ValueKey("AuthGateLoadingIndicator"), // For testing
              ),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // Navigate to your main app content when the user is authenticated.
          // AppShell might need AuthService if its children do and you're not using Provider for it there.
          // Or, AppShell itself could be fetching AuthService via Provider.
          return const AppShell(); // Assuming AppShell can get AuthService if needed
        }

        // User is not logged in, show the LoginScreen.
        // The LoginScreen will then handle presenting the AuthModal.
        return LoginScreen(authService: authService);
      },
    );
  }
}

// This screen is shown by AuthGate when no user is logged in.
// Its primary purpose is to provide a context and trigger for showing the AuthModal.
class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({
    super.key,
    required this.authService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Flag to help manage modal presentation, e.g., to prevent multiple modals
  // if this screen rebuilds rapidly for some reason.
  bool _isModalBeingPresented = false;

  @override
  void initState() {
    super.initState();
    // Attempt to show the modal as soon as this screen is built.
    // WidgetsBinding.instance.addPostFrameCallback ensures this runs after the build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAuthModalIfNeeded();
    });
  }

  // This method can be called to show the modal.
  // It's also used by the button on this screen.
  void _showAuthModalIfNeeded() {
    // Check if the widget is still mounted and if a modal isn't already flagged as being presented.
    if (mounted && !_isModalBeingPresented) {
      setState(() {
        _isModalBeingPresented = true; // Set flag before showing modal
      });

      AuthModal.show(context, authService: widget.authService).then((_) {
        // This .then() callback executes after the AuthModal is dismissed.
        if (mounted) {
          setState(() {
            _isModalBeingPresented = false; // Reset flag
          });
          // If the user successfully logged in, the AuthGate's StreamBuilder
          // will detect the change in authStateChanges and rebuild, showing AppShell.
          // If the user cancelled the modal and is still not logged in,
          // they will remain on this LoginScreen. They can then use the button to try again.
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen provides a basic UI and a button to trigger the AuthModal.
    // It's displayed when the user is not authenticated.
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface, // Use theme color
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // You can add your app logo or branding here
              // Example: FlutterLogo(size: 80),
              Icon(
                Icons.lock_outline_rounded, // A generic lock icon
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 30),
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Please sign in or create an account to continue to your amazing app.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    textStyle: Theme.of(context).textTheme.labelLarge,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0))),
                onPressed:
                    _showAuthModalIfNeeded, // Allow user to re-trigger the modal
                child: const Text('Login / Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
