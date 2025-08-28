import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projectastra/models/task_models.dart';
import 'package:projectastra/services/auth_service.dart'; // Assuming AuthService is available

class TaskService {
  final AuthService _authService;
  final String _backendBaseUrl = 'http://localhost:5000/api'; // Adjust as needed

  TaskService(this._authService);

  Future<List<Task>> fetchTasks(String provider, {String? listId}) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token.');
    }

    String url;
    if (provider == 'googleTasks') {
      url = '$_backendBaseUrl/tasks/google/tasks'; // Assuming backend endpoint
    } else if (provider == 'microsoftToDo') {
      if (listId == null) {
        // First, fetch default task list if not provided
        final lists = await fetchTaskLists(provider);
        if (lists.isNotEmpty) {
          listId = lists.first['id']; // Use the first list as default
        } else {
          throw Exception('No Microsoft To Do lists found.');
        }
      }
      url = '$_backendBaseUrl/todo/tasks/$listId'; // Assuming backend endpoint
    } else {
      throw Exception('Unsupported task provider: $provider');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> taskJson = json.decode(response.body);
      return taskJson.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tasks: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTaskLists(String provider) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token.');
    }

    String url;
    if (provider == 'googleTasks') {
      url = '$_backendBaseUrl/tasks/google/tasklists'; // Assuming backend endpoint
    } else if (provider == 'microsoftToDo') {
      url = '$_backendBaseUrl/todo/task_lists'; // Assuming backend endpoint
    } else {
      throw Exception('Unsupported task provider: $provider');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load task lists: ${response.body}');
    }
  }

  Future<Task> createTask(String provider, String title, {String? listId, DateTime? dueDate}) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token.');
    }

    String url;
    Map<String, dynamic> payload = {'title': title};
    if (dueDate != null) {
      payload['due_date'] = dueDate.toIso8601String();
    }

    if (provider == 'googleTasks') {
      url = '$_backendBaseUrl/tasks/google/tasks'; // Assuming backend endpoint
      if (listId != null) {
        payload['task_list_id'] = listId;
      }
    } else if (provider == 'microsoftToDo') {
      if (listId == null) {
        final lists = await fetchTaskLists(provider);
        if (lists.isNotEmpty) {
          listId = lists.first['id'];
        } else {
          throw Exception('No Microsoft To Do lists found to create task in.');
        }
      }
      url = '$_backendBaseUrl/todo/tasks/$listId'; // Assuming backend endpoint
    } else {
      throw Exception('Unsupported task provider: $provider');
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
      return Task.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create task: ${response.body}');
    }
  }

  Future<void> updateTask(String provider, String listId, String taskId, {String? title, bool? isCompleted, DateTime? dueDate}) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token.');
    }

    String url;
    Map<String, dynamic> payload = {};
    if (title != null) payload['title'] = title;
    if (isCompleted != null) payload['is_completed'] = isCompleted;
    if (dueDate != null) payload['due_date'] = dueDate.toIso8601String();

    if (provider == 'googleTasks') {
      url = '$_backendBaseUrl/tasks/google/tasks/$listId/$taskId'; // Assuming backend endpoint
    } else if (provider == 'microsoftToDo') {
      url = '$_backendBaseUrl/todo/tasks/$listId/$taskId'; // Assuming backend endpoint
    } else {
      throw Exception('Unsupported task provider: $provider');
    }

    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task: ${response.body}');
    }
  }

  Future<void> deleteTask(String provider, String listId, String taskId) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token.');
    }

    String url;
    if (provider == 'googleTasks') {
      url = '$_backendBaseUrl/tasks/google/tasks/$listId/$taskId'; // Assuming backend endpoint
    } else if (provider == 'microsoftToDo') {
      url = '$_backendBaseUrl/todo/tasks/$listId/$taskId'; // Assuming backend endpoint
    } else {
      throw Exception('Unsupported task provider: $provider');
    }

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task: ${response.body}');
    }
  }
}