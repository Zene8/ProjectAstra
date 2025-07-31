import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For User object
// Adjust the import path to your AuthService location
import 'package:projectastra/services/auth_service.dart'; // Placeholder - ADJUST THIS PATH
// Adjust the import path to your AuthModal location
import 'package:projectastra/widgets/auth/auth_modal.dart'; // Placeholder - ADJUST THIS PATH

// For Image Picking (you'll need to add these dependencies to pubspec.yaml)
// import 'package:image_picker/image_picker.dart';
// For Firebase Storage (you'll need to add this dependency and set up Storage)
// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io'; // For File type if using image_picker

// For launching URLs (needed for OAuth flows)
// import 'package:url_launcher/url_launcher.dart';
// For Google APIs (if connecting to Gmail, Drive, etc.)
// import 'package:googleapis/gmail/v1.dart' as gmail;
// import 'package:googleapis/drive/v3.dart' as drive;
// import 'package:google_sign_in/google_sign_in.dart' as official_google_sign_in; // For getting OAuth scopes/tokens

class UserSettingsPage extends StatefulWidget {
  final AuthService authService;

  const UserSettingsPage({
    super.key,
    required this.authService,
  });

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  User? _currentUser;
  bool _isUpdatingProfile = false;
  // bool _isGmailConnected = false; // Example state for connected apps
  // bool _isDriveConnected = false; // Example state for connected apps

  @override
  void initState() {
    super.initState();
    _currentUser = widget.authService.currentUser;
    widget.authService.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
    // _loadConnectedAppsStatus();
  }

  // Future<void> _loadConnectedAppsStatus() async { /* ... */ }

  Future<void> _refreshUser() async {
    if (!mounted) return;
    setState(() => _isUpdatingProfile = true);
    User? refreshedUser = await widget.authService.getRefreshedUser();
    if (mounted) {
      setState(() {
        _currentUser = refreshedUser;
        _isUpdatingProfile = false;
      });
    }
  }

  Future<void> _showChangeDisplayNameDialog(BuildContext context) async {
    final displayNameController =
        TextEditingController(text: _currentUser?.displayName ?? '');
    final formKey = GlobalKey<FormState>();
    bool isLoadingDialog = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: !isLoadingDialog,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Change Display Name'),
            content: Form(
              // Ensure Form has a child
              key: formKey,
              child: TextFormField(
                // This is the child of the Form
                controller: displayNameController,
                decoration:
                    const InputDecoration(labelText: 'New Display Name'),
                validator: (value) => value!.trim().isEmpty
                    ? 'Display name cannot be empty'
                    : null,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: isLoadingDialog
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoadingDialog
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isLoadingDialog = true);
                          final newName = displayNameController.text.trim();
                          final success = await widget.authService
                              .updateDisplayName(newName);

                          if (mounted) {
                            Navigator.of(dialogContext).pop();
                            if (success) {
                              await _refreshUser();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Display name updated!')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Failed to update display name.')),
                              );
                            }
                          }
                        }
                      },
                child: isLoadingDialog
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _showChangeProfilePictureDialog(BuildContext context) async {
    if (_currentUser == null) return;
    // ... (placeholder PFP logic as before) ...
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Change PFP: Image picker and upload not implemented yet.')),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmNewPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoadingDialog = false;

    currentPasswordController.text = '';
    newPasswordController.text = '';
    confirmNewPasswordController.text = '';

    return showDialog<void>(
      context: context,
      barrierDismissible: !isLoadingDialog,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: SingleChildScrollView(
              child: Form(
                // Ensure Form has a child
                key: formKey,
                child: ListBody(
                  // This is the child of the Form
                  children: <Widget>[
                    TextFormField(
                      controller: currentPasswordController,
                      decoration:
                          const InputDecoration(labelText: 'Current Password'),
                      obscureText: true,
                      validator: (value) => value!.isEmpty
                          ? 'Please enter your current password'
                          : null,
                    ),
                    TextFormField(
                      controller: newPasswordController,
                      decoration:
                          const InputDecoration(labelText: 'New Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: confirmNewPasswordController,
                      decoration: const InputDecoration(
                          labelText: 'Confirm New Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: isLoadingDialog
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoadingDialog
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isLoadingDialog = true);
                          final success =
                              await widget.authService.changePassword(
                            currentPasswordController.text,
                            newPasswordController.text,
                          );
                          if (mounted) {
                            Navigator.of(dialogContext).pop();
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Password changed successfully!')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Failed to change password. Check current password or try again.')),
                              );
                            }
                          }
                        } else {
                          setDialogState(() => isLoadingDialog = false);
                        }
                      },
                child: isLoadingDialog
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Change'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoadingDialog = false;
    currentPasswordController.text = '';

    return showDialog<void>(
      context: context,
      barrierDismissible: !isLoadingDialog,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Delete Account'),
            content: SingleChildScrollView(
              child: Form(
                // Ensure Form has a child
                key: formKey,
                child: ListBody(
                  // This is the child of the Form
                  children: <Widget>[
                    const Text(
                        'This action is permanent. Please enter your current password to confirm.'),
                    TextFormField(
                      controller: currentPasswordController,
                      decoration:
                          const InputDecoration(labelText: 'Current Password'),
                      obscureText: true,
                      validator: (value) => value!.isEmpty
                          ? 'Please enter your password to confirm deletion'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: isLoadingDialog
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isLoadingDialog
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isLoadingDialog = true);
                          final success = await widget.authService
                              .deleteAccount(currentPasswordController.text);
                          if (mounted) {
                            Navigator.of(dialogContext).pop();
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Account deleted successfully.')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Failed to delete account. Check password or try again.')),
                              );
                            }
                          }
                        } else {
                          setDialogState(() => isLoadingDialog = false);
                        }
                      },
                child: isLoadingDialog
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Delete My Account',
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _connectGmail(BuildContext context) async {
    /* ... (as before) ... */
  }
  Future<void> _disconnectGmail(BuildContext context) async {
    /* ... (as before) ... */
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest of build method, including the check for _currentUser == null,
    // and the ListView for settings items are assumed to be as previously provided
    // and correct. The fix is focused on the Form widgets within the dialogs.)

    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final listTileTitleStyle = theme.textTheme.titleMedium;
    final listTileIconColor = theme.iconTheme.color;

    if (_currentUser == null) {
      Future.microtask(() {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          AuthModal.show(context, authService: widget.authService).then((_) {
            if (widget.authService.currentUser == null &&
                (ModalRoute.of(context)?.isCurrent ?? false) &&
                Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              _refreshUser();
            }
          });
        }
      });
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Settings'),
          automaticallyImplyLeading: Navigator.canPop(context),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading authentication...'),
            ],
          ),
        ),
      );
    }

    final String userName = _currentUser!.displayName ?? "User Name";
    final String userEmail = _currentUser!.email ?? "user@example.com";
    final String? userPhotoURL = _currentUser!.photoURL;
    final bool willUseBackgroundImage =
        userPhotoURL != null && userPhotoURL.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Settings'),
      ),
      body: _isUpdatingProfile
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Section
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showChangeProfilePictureDialog(context),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: willUseBackgroundImage
                            ? NetworkImage(userPhotoURL)
                            : null,
                        onBackgroundImageError: willUseBackgroundImage
                            ? (exception, stackTrace) {
                                print("Error loading avatar image: $exception");
                              }
                            : null,
                        child: !willUseBackgroundImage
                            ? Icon(Icons.person,
                                size: 40, color: Colors.grey.shade700)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userEmail,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 20, color: listTileIconColor),
                      tooltip: "Edit display name",
                      onPressed: () => _showChangeDisplayNameDialog(context),
                    )
                  ],
                ),
                const SizedBox(height: 32),

                // Account Settings
                Text('Account', style: titleStyle),
                const Divider(height: 20),
                ListTile(
                  leading: Icon(Icons.badge_outlined, color: listTileIconColor),
                  title: Text('Change Display Name', style: listTileTitleStyle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangeDisplayNameDialog(context),
                ),
                ListTile(
                  leading: Icon(Icons.image_outlined, color: listTileIconColor),
                  title:
                      Text('Change Profile Picture', style: listTileTitleStyle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangeProfilePictureDialog(context),
                ),
                ListTile(
                  leading: Icon(Icons.lock_outline, color: listTileIconColor),
                  title: Text('Change Password', style: listTileTitleStyle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (_currentUser!.providerData.any((userInfo) =>
                        userInfo.providerId == EmailAuthProvider.PROVIDER_ID)) {
                      _showChangePasswordDialog(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Password change is not available for accounts signed in with social providers directly here.')),
                      );
                    }
                  },
                ),

                const SizedBox(height: 32),

                // Connected Apps Section
                Text('Connected Apps', style: titleStyle),
                const Divider(height: 20),
                ListTile(
                  leading: Icon(Icons.email_outlined, color: listTileIconColor),
                  title: Text('Gmail', style: listTileTitleStyle),
                  trailing: ElevatedButton(
                    // Placeholder
                    onPressed: () => _connectGmail(context),
                    child: Text("Connect"),
                  ),
                  onTap: () {
                    _connectGmail(context);
                  },
                ),
                const SizedBox(height: 32),

                // App Settings
                Text('Preferences', style: titleStyle),
                const Divider(height: 20),
                ListTile(
                  leading: Icon(Icons.color_lens_outlined, color: listTileIconColor),
                  title: Text('Theme Settings', style: listTileTitleStyle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implement theme customization dialog
                    print("Theme settings tapped");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Theme customization not implemented yet.')),
                    );
                  },
                ),
                SwitchListTile(
                  secondary:
                      Icon(Icons.dark_mode_outlined, color: listTileIconColor),
                  title: Text('Dark Mode', style: listTileTitleStyle),
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (val) {
                    print("Dark Mode toggled: $val");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Theme switching not implemented yet.')),
                    );
                  },
                  activeColor: Colors.lightBlueAccent,
                ),
                SwitchListTile(
                  secondary: Icon(Icons.notifications_outlined,
                      color: listTileIconColor),
                  title: Text('Notifications', style: listTileTitleStyle),
                  value: true,
                  onChanged: (val) {
                    print("Notifications toggled: $val");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Notification settings not implemented yet.')),
                    );
                  },
                  activeColor: Colors.lightBlueAccent,
                ),

                const SizedBox(height: 32),

                // Security Section
                Text('Security & Data', style: titleStyle),
                const Divider(height: 20),
                ListTile(
                  leading: Icon(Icons.logout, color: listTileIconColor),
                  title: Text('Log Out', style: listTileTitleStyle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Log Out'),
                        content:
                            const Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await widget.authService.signOut();
                              print("Logged out");
                            },
                            child: const Text('Log Out',
                                style: TextStyle(color: Colors.orange)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                  title: Text(
                    'Delete Account',
                    style: listTileTitleStyle?.copyWith(color: Colors.red[400]),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.red[400]),
                  onTap: () {
                    if (_currentUser!.providerData.any((userInfo) =>
                        userInfo.providerId == EmailAuthProvider.PROVIDER_ID)) {
                      _showDeleteAccountDialog(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Account deletion via this flow requires password re-authentication.')),
                      );
                    }
                  },
                ),
              ],
            ),
    );
  }
}
