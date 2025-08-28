// Suggested path: lib/features/chat/services/chat_api_service.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb; // Added kIsWeb
import 'package:http/http.dart' as http;

import 'package:project_astra/services/application_context_notifier.dart'; // Import the notifier
import 'package:project_astra/models/application_context.dart'; // Import the model

class ChatApiService {
  static const String _androidEmulatorHost = "10.0.2.2";
  static const String _defaultHost = "127.0.0.1";
  static const String _port = "5000";
  static const String _path = "/api/chat";
  static const String _productionApiUrl =
      "https://your-production-api.com/chat"; // REPLACE

  late final String _chatApiUrl;
  final ApplicationContextNotifier _applicationContextNotifier; // Add notifier instance

  ChatApiService(this._applicationContextNotifier) { // Modify constructor
    if (kDebugMode) {
      String host = _defaultHost;
      if (!kIsWeb && Platform.isAndroid) {
        // kIsWeb check for web platform
        host = _androidEmulatorHost;
      }
      // For physical devices in debug mode on the same network:
      // host = "YOUR_COMPUTER_LOCAL_IP"; // e.g., "192.168.1.100"
      _chatApiUrl = "http://$host:$_port$_path";
      print("ChatApiService: Using DEBUG URL: $_chatApiUrl");
    } else {
      _chatApiUrl = _productionApiUrl;
      print("ChatApiService: Using PRODUCTION URL: $_chatApiUrl");
    }
  }

  Future<Map<String, dynamic>> sendMessageToBackend(String userMessage, {String? aiBackend}) async {
    try {
      final List<Map<String, dynamic>> contextsJson = _applicationContextNotifier.contexts
          .map((context) => context.toJson())
          .toList();

      final Map<String, dynamic> requestBody = {
        "message": userMessage,
        "context": contextsJson,
      };

      if (aiBackend != null) {
        requestBody["ai_backend"] = aiBackend;
      }

      print(
        "ChatApiService: Sending message to $_chatApiUrl with body: ${jsonEncode(requestBody)}",
      );
      final response = await http.post(
        Uri.parse(_chatApiUrl),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        }, // Specify charset
        body: jsonEncode(requestBody),
      );

      // Decode with utf8 to handle special characters correctly
      final String responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('final_answer')) {
          // Parse suggested actions
          List<SuggestedAction>? suggestedActions;
          if (responseData.containsKey('suggested_actions') &&
              responseData['suggested_actions'] is List) {
            suggestedActions = (responseData['suggested_actions'] as List)
                .map((e) => SuggestedAction.fromJson(e as Map<String, dynamic>))
                .toList();
          }

          return {
            'final_answer':
                responseData['final_answer'] as String? ??
                "Error: Missing 'final_answer'.",
            'thinking':
                responseData['thinking'] as String? ??
                "", // Default empty string for thinking
            'suggested_actions': suggestedActions, // Include suggested actions
          };
        } else {
          print("Unexpected response format from backend: $responseData");
          throw Exception(
            "Unexpected response format from backend. Missing 'final_answer'.",
          );
        }
      } else {
        print("Error from server: ${response.statusCode} $responseBody");
        String detail = "Server error";
        try {
          final errorJson = jsonDecode(responseBody);
          if (errorJson is Map && errorJson.containsKey('detail')) {
            detail = errorJson['detail'];
          } else {
            detail = responseBody;
          }
        } catch (e) {
          // responseBody was not JSON or did not have 'detail'
          detail =
              responseBody.isNotEmpty
                  ? responseBody
                  : "Status Code: ${response.statusCode}";
        }
        throw Exception("Server error: $detail");
      }
    } catch (e) {
      print("ChatApiService Error sending message: $e");
      throw Exception(
        "Failed to get response from AI. Details: ${e.toString().replaceFirst("Exception: ", "")}",
      );
    }
  }
}
