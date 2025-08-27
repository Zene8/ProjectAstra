import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PfpService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<String?> uploadProfilePicture(XFile imageFile) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        print("No user signed in.");
        return null;
      }

      // Create a reference to the Firebase Storage location
      // Using user.uid ensures each user has their own folder for profile pictures
      final ref = _firebaseStorage.ref().child('profile_pictures').child('${user.uid}.jpg');

      // Upload the file
      await ref.putFile(File(imageFile.path));

      // Get the download URL
      final String downloadUrl = await ref.getDownloadURL();

      // Update the user's profile with the new photo URL
      await user.updatePhotoURL(downloadUrl);
      await user.reload(); // Reload user to get updated photoURL

      print("Profile picture uploaded and updated successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("Error uploading profile picture: $e");
      return null;
    }
  }

  Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      return image;
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  // Method to get the current user's profile picture URL
  String? getCurrentUserPhotoUrl() {
    return _firebaseAuth.currentUser?.photoURL;
  }
}
