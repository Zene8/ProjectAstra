import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projectastra/models/document_models.dart';
import 'package:projectastra/services/auth_service.dart'; // Assuming AuthService is available

class DocumentService {
  final AuthService _authService;
  final String _backendBaseUrl = 'http://localhost:5000/api'; // Adjust as needed

  DocumentService(this._authService);

  Future<List<Document>> listDocuments(String provider, {String? folderId}) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token.');
    }

    String url;
    if (provider == 'googleDrive') {
      url = '$_backendBaseUrl/documents/google/files'; // Assuming backend endpoint
      if (folderId != null) {
        url += '?folder_id=$folderId';
      }
    } else if (provider == 'oneDrive') {
      url = '$_backendBaseUrl/onedrive/files'; // Assuming backend endpoint
      if (folderId != null) {
        url += '?path=$folderId'; // OneDrive uses path
      }
    } else {
      throw Exception('Unsupported document provider: $provider');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> docJson = json.decode(response.body);
      return docJson.map((json) => Document.fromJson(json)).toList();
    } else {
      throw Exception('Failed to list documents: ${response.body}');
    }
  }

  Future<String> downloadDocumentContent(String provider, String documentId) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token.');
    }

    String url;
    if (provider == 'googleDrive') {
      url = '$_backendBaseUrl/documents/google/download/$documentId'; // Assuming backend endpoint
    } else if (provider == 'oneDrive') {
      url = '$_backendBaseUrl/onedrive/download/$documentId'; // Assuming backend endpoint
    } else {
      throw Exception('Unsupported document provider: $provider');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return response.body; // Assuming content is returned as plain text
    } else {
      throw Exception('Failed to download document content: ${response.body}');
    }
  }

  Future<Document> uploadDocument(String provider, String fileName, String content, {String? folderId}) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token.');
    }

    String url;
    Map<String, dynamic> payload = {
      'file_name': fileName,
      'content': content,
    };
    if (folderId != null) {
      payload['folder_id'] = folderId;
    }

    if (provider == 'googleDrive') {
      url = '$_backendBaseUrl/documents/google/upload'; // Assuming backend endpoint
    } else if (provider == 'oneDrive') {
      url = '$_backendBaseUrl/onedrive/upload'; // Assuming backend endpoint
    } else {
      throw Exception('Unsupported document provider: $provider');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Document.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to upload document: ${response.body}');
    }
  }

  Future<void> deleteDocument(String provider, String documentId) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token.');
    }

    String url;
    if (provider == 'googleDrive') {
      url = '$_backendBaseUrl/documents/google/delete/$documentId'; // Assuming backend endpoint
    } else if (provider == 'oneDrive') {
      url = '$_backendBaseUrl/onedrive/delete/$documentId'; // Assuming backend endpoint
    } else {
      throw Exception('Unsupported document provider: $provider');
    }

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete document: ${response.body}');
    }
  }
}