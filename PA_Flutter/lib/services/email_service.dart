import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projectastra/models/email_models.dart';
import 'package:projectastra/services/auth_service.dart'; // Assuming AuthService is available

class EmailService {
  final AuthService _authService;
  final String _backendBaseUrl = 'http://localhost:5000/api'; // Adjust as needed

  EmailService(this._authService);

  Future<List<Email>> fetchEmails(String provider) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token.');
    }

    String url;
    if (provider == 'gmail') {
      url = '$_backendBaseUrl/email/gmail/inbox'; // Assuming backend endpoint
    } else if (provider == 'outlook') {
      url = '$_backendBaseUrl/outlook/inbox'; // Assuming backend endpoint
    } else {
      throw Exception('Unsupported email provider: $provider');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> emailJson = json.decode(response.body);
      return emailJson.map((json) => Email.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load emails: ${response.body}');
    }
  }

  Future<void> sendEmail(String provider, String recipient, String subject, String body) async {
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
      'recipient_email': recipient,
      'subject': subject,
      'body': body,
    };

    if (provider == 'gmail') {
      url = '$_backendBaseUrl/email/gmail/send'; // Assuming backend endpoint
    } else if (provider == 'outlook') {
      url = '$_backendBaseUrl/outlook/send_email'; // Assuming backend endpoint
    } else {
      throw Exception('Unsupported email provider: $provider');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send email: ${response.body}');
    }
  }
}