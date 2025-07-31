import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'
    as official_google_sign_in; // For mobile
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart'; // For TargetPlatform

// Import for google_sign_in_all_platforms (for desktop)
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    as all_platforms_google_sign_in;
// http package might be needed if the new package doesn't directly give idToken and you need to fetch it,
// but usually, its credentials object should suffice.
// import 'package:http/http.dart' as http;
// import 'dart:convert'; // For json.decode

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // This instance is for the official google_sign_in, primarily for mobile.
  final official_google_sign_in.GoogleSignIn _googleSignIn =
      official_google_sign_in.GoogleSignIn();

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential?> signUpWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print("Signed up successfully: ${userCredential.user?.uid}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Failed to sign up: ${e.message} (Code: ${e.code})');
      return null;
    } catch (e) {
      print('An unexpected error occurred during sign up: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print("Signed in successfully: ${userCredential.user?.uid}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Failed to sign in: ${e.message} (Code: ${e.code})');
      return null;
    } catch (e) {
      print('An unexpected error occurred during sign in: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      print("Attempting Google Sign-In...");
      UserCredential? userCredential;

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        print("Using signInWithPopup for Web.");
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        bool isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux;

        if (isDesktop) {
          print(
              "Using google_sign_in_all_platforms for Desktop Google Sign-In.");

          // IMPORTANT: Replace these placeholders with your actual values.
          // clientId and clientSecret are from your Google Cloud Console OAuth 2.0 Client ID (typically "Web application" type).
          const String desktopClientId =
              "921780484273-c276sq894336m7gjm55m7o81vao13i9a.apps.googleusercontent.com";
          const String desktopClientSecret =
              "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";
          const int desktopRedirectPort =
              3000; // Choose a port (e.g., 3000, 8080)

          // Ensure http://localhost:desktopRedirectPort is an authorized redirect URI in Google Cloud Console.

          final desktopGoogleSignIn = all_platforms_google_sign_in.GoogleSignIn(
            params: all_platforms_google_sign_in.GoogleSignInParams(
              clientId: desktopClientId,
              clientSecret: desktopClientSecret,
              redirectPort: desktopRedirectPort,
              scopes: [
                // Default scopes are usually sufficient for Firebase Auth
                'email',
                'profile',
                'openid', // openid is important for getting an ID token
              ],
              // Optional: You can provide functions for token storage if needed by the package for desktop persistence
              // saveAccessToken: (token) async { /* custom save logic */ },
              // retrieveAccessToken: () async { /* custom retrieve logic */ return null; },
              // deleteAccessToken: () async { /* custom delete logic */ },
            ),
          );

          final all_platforms_google_sign_in.GoogleSignInCredentials?
              credentials =
              await desktopGoogleSignIn.signIn(); // signInOnline() or signIn()

          if (credentials == null) {
            print(
                "Google Sign-In via google_sign_in_all_platforms cancelled or failed.");
            return null;
          }

          print(
              "google_sign_in_all_platforms: AccessToken received: ${credentials.accessToken != null}");
          // The package documentation mentions credentials.accessToken.
          // We need to check if it also provides an idToken or if the accessToken is an ID Token itself
          // or if we need to make another call to get user info / ID token.
          // For Firebase, an ID token is preferred, but an access token can sometimes be used.

          // Let's assume credentials.idToken might exist or accessToken is what we use.
          // Firebase's GoogleAuthProvider.credential can accept idToken and/or accessToken.
          final AuthCredential credential = GoogleAuthProvider.credential(
            idToken: credentials.idToken, // Use if available
            accessToken: credentials.accessToken, // Use if available
          );

          if (credentials.idToken == null && credentials.accessToken == null) {
            print(
                "google_sign_in_all_platforms: Neither ID token nor Access token received.");
            return null;
          }

          userCredential = await _firebaseAuth.signInWithCredential(credential);
        } else {
          // Mobile flow (using official google_sign_in package)
          print("Using official GoogleSignIn package for Mobile.");
          final official_google_sign_in.GoogleSignInAccount?
              googleSignInAccount = await _googleSignIn.signIn();

          if (googleSignInAccount == null) {
            print("Google Sign-In aborted by user (Mobile).");
            return null;
          }
          final official_google_sign_in.GoogleSignInAuthentication
              googleSignInAuthentication =
              await googleSignInAccount.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleSignInAuthentication.accessToken,
            idToken: googleSignInAuthentication.idToken,
          );
          userCredential = await _firebaseAuth.signInWithCredential(credential);
        }
      }

      print("Google Sign-In successful: ${userCredential.user?.displayName}");
          return userCredential;
    } on FirebaseAuthException catch (e) {
      print(
          "Firebase Auth Exception during Google Sign-In: ${e.message} (Code: ${e.code})");
      // ... (specific error handling as before) ...
      return null;
    } catch (e) {
      print("An unexpected error occurred during Google Sign-In: $e");
      if (e.toString().contains("SocketException") ||
          e.toString().contains("TimeoutException")) {
        print("Potential issue with local server for redirect URI or network.");
      }
      return null;
    }
  }

  Future<bool> updateDisplayName(String newName) async {
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        print("Updating display name to: $newName");
        await user.updateDisplayName(newName);
        await user.reload();
        print("Display name updated successfully.");
        return true;
      } on FirebaseAuthException catch (e) {
        print("Error updating display name: ${e.message} (Code: ${e.code})");
        return false;
      } catch (e) {
        print("An unexpected error occurred updating display name: $e");
        return false;
      }
    }
    print("No user signed in to update display name.");
    return false;
  }

  Future<bool> updatePhotoURL(String newPhotoURL) async {
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        print("Updating photo URL to: $newPhotoURL");
        await user.updatePhotoURL(newPhotoURL);
        await user.reload();
        print("Photo URL updated successfully.");
        return true;
      } on FirebaseAuthException catch (e) {
        print("Error updating photo URL: ${e.message} (Code: ${e.code})");
        return false;
      } catch (e) {
        print("An unexpected error occurred updating photo URL: $e");
        return false;
      }
    }
    print("No user signed in to update photo URL.");
    return false;
  }

  Future<User?> getRefreshedUser() async {
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.reload();
        return _firebaseAuth.currentUser;
      } catch (e) {
        print("Error reloading user: $e");
        return user;
      }
    }
    return null;
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    User? user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      print(
          "No user signed in or user has no email (required for email/password provider re-auth).");
      return false;
    }
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    try {
      print("Re-authenticating user for password change...");
      await user.reauthenticateWithCredential(credential);
      print("Re-authentication successful. Updating password...");
      await user.updatePassword(newPassword);
      await user.reload();
      print("Password updated successfully.");
      return true;
    } on FirebaseAuthException catch (e) {
      print("Failed to change password: ${e.message} (Code: ${e.code})");
      return false;
    } catch (e) {
      print("An unexpected error occurred during password change: $e");
      return false;
    }
  }

  Future<bool> deleteAccount(String currentPassword) async {
    User? user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      print(
          "No user signed in or user has no email (required for email/password provider re-auth).");
      return false;
    }
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    try {
      print("Re-authenticating user for account deletion...");
      await user.reauthenticateWithCredential(credential);
      print("Re-authentication successful. Deleting account...");
      await user.delete();
      print("Account deleted successfully.");
      return true;
    } on FirebaseAuthException catch (e) {
      print("Failed to delete account: ${e.message} (Code: ${e.code})");
      return false;
    } catch (e) {
      print("An unexpected error occurred during account deletion: $e");
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from the official google_sign_in if it was used (mobile)
      if (await _googleSignIn.isSignedIn()) {
        print("Signing out from official GoogleSignIn package...");
        await _googleSignIn.signOut();
      }

      // For google_sign_in_all_platforms, it also has a signOut method.
      // If you maintain a separate instance for it, you'd call signOut on that too.
      // However, if the desktop flow creates a local instance, that instance goes out of scope.
      // The primary action is to sign out from Firebase.
      // The package's example shows instantiating GoogleSignIn and then calling signOut on that instance.
      // If you need to ensure the desktop-specific session is cleared beyond Firebase,
      // you might need to call signOut on a persisted instance of all_platforms_google_sign_in.GoogleSignIn
      // or rely on its token deletion mechanism if configured.
      // For simplicity here, we focus on Firebase and the mobile GoogleSignIn instance.
    } catch (e) {
      print("Error during Google sign out (official or all_platforms): $e");
    }

    try {
      await _firebaseAuth.signOut();
      print("Signed out from Firebase successfully.");
    } catch (e) {
      print("Error signing out from Firebase: $e");
    }
  }
}
