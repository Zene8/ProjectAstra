import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // For FirebaseException
// Make sure your AuthService import path is correct for your project structure
// Example: import 'package:your_project_name/services/auth_service.dart';
import 'package:projectastra/services/auth_service.dart'; // Placeholder - ADJUST THIS PATH

// Define the StatefulWidget 'AuthModal'
class AuthModal extends StatefulWidget {
  final AuthService authService;

  const AuthModal({
    super.key,
    required this.authService,
  });

  static Future<void> show(BuildContext context,
      {required AuthService authService}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // User can dismiss by tapping outside
      builder: (BuildContext dialogContext) {
        // Pass the authService to the AuthModal instance
        return AuthModal(authService: authService);
      },
    );
  }

  @override
  _AuthModalState createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // For sign up

  bool _isLoginMode = true; // true for Login, false for Sign Up
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Ensured this is uncommented
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null; // Clear error message when switching modes
      _formKey.currentState?.reset(); // Reset form validation state
      // Clear text controllers when switching modes for a cleaner UX
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _submitEmailPasswordForm() async {
    // Validate form before proceeding
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Don't proceed if form is not valid
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLoginMode) {
        await widget.authService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        // Sign Up mode
        // Ensure passwords match (already part of validator, but good for explicit check if needed elsewhere)
        if (_passwordController.text != _confirmPasswordController.text) {
          if (mounted) {
            // Check if the widget is still in the tree
            setState(() {
              _errorMessage = "Passwords do not match.";
              _isLoading =
                  false; // Stop loading as this is a client-side validation fail
            });
          }
          return;
        }
        await widget.authService.signUpWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      // If successful, Firebase authStateChanges should trigger navigation in your app.
      // Pop the modal.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          // Handle FirebaseException specifically for better messages, fallback to generic toString
          _errorMessage = (e is FirebaseException)
              ? e.message ??
                  "An unknown Firebase error occurred." // Use null-aware operator for e.message
              : e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await widget.authService.signInWithGoogle();
      // If successful, Firebase authStateChanges should trigger navigation.
      // Pop the modal.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = (e is FirebaseException)
              ? e.message ??
                  "An unknown Firebase error occurred during Google Sign-In."
              : e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(
          child: Text(_isLoginMode ? "Login" : "Sign Up",
              style: TextStyle(fontWeight: FontWeight.bold))),
      contentPadding: EdgeInsets.all(20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important for AlertDialog content
            children: <Widget>[
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "you@example.com",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your email.";
                  }
                  // Common email regex
                  if (!RegExp(
                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                      .hasMatch(value.trim())) {
                    return "Please enter a valid email.";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  // Consider adding a suffixIcon to toggle password visibility
                ),
                obscureText: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your password.";
                  }
                  if (!_isLoginMode && value.length < 6) {
                    // Stricter for sign up for security
                    return "Password must be at least 6 characters.";
                  }
                  return null;
                },
              ),
              // Confirm Password Field for Sign Up
              if (!_isLoginMode) ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon:
                        Icon(Icons.password_outlined), // Changed icon here
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  obscureText: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm your password.";
                    }
                    if (value != _passwordController.text) {
                      return "Passwords do not match.";
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 20),

              // Error Message Display
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Loading Indicator or Submit Button
              _isLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10.0), // Give some space for loader
                      child: CircularProgressIndicator(),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48), // Full width
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        // Consider adding theming for button color
                      ),
                      onPressed: _submitEmailPasswordForm,
                      child: Text(_isLoginMode ? "Login" : "Create Account"),
                    ),
              SizedBox(height: 12),

              // "OR" Divider and Google Sign-In Button
              if (!_isLoading) ...[
                Row(
                  children: <Widget>[
                    Expanded(
                        child: Divider(
                            thickness: 0.5, color: Colors.grey.shade400)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text("OR",
                          style: TextStyle(color: Colors.grey.shade600)),
                    ),
                    Expanded(
                        child: Divider(
                            thickness: 0.5, color: Colors.grey.shade400)),
                  ],
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.g_mobiledata_outlined,
                      size: 24.0), // Replaced Image.asset
                  label: Text("Continue with Google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Google's recommended style
                    foregroundColor: Colors.black87, // Text color
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(
                          color: Colors.grey.shade300), // Subtle border
                    ),
                    elevation: 1, // Slight shadow
                  ),
                  onPressed: _handleGoogleSignIn,
                ),
              ],
              SizedBox(height: 16),

              // Toggle Mode Button
              if (!_isLoading)
                TextButton(
                  onPressed: _toggleMode,
                  child: Text(
                    _isLoginMode
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Login",
                  ),
                ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        if (!_isLoading) // Hide cancel button when loading to prevent accidental dismissal
          TextButton(
            child: Text("Cancel",
                style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color
                        ?.withOpacity(0.7))),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
      ],
    );
  }
}
