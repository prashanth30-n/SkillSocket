import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TodoService {
  static const String baseUrl = 'https://skillsocket-backend.onrender.com/api';

  // Get auth token from shared preferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get headers with authorization
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Format date as YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get todos for a specific date
  // GET /api/todos?date=YYYY-MM-DD
  static Future<List<Map<String, dynamic>>?> getTodos(DateTime date) async {
    try {
      final headers = await _getHeaders();
      final dateStr = _formatDate(date);

      final response = await http.get(
        Uri.parse('$baseUrl/todos?date=$dateStr'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => {
                  '_id': item['_id'],
                  'task': item['task'],
                  'done': item['done'],
                  'date': item['date'],
                })
            .toList();
      } else {
        print('Get todos error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Get todos exception: $e');
      return null;
    }
  }

  // Create a new todo
  // POST /api/todos { date: 'YYYY-MM-DD', task: string }
  static Future<Map<String, dynamic>?> createTodo(
      DateTime date, String task) async {
    try {
      final headers = await _getHeaders();
      final dateStr = _formatDate(date);

      final response = await http.post(
        Uri.parse('$baseUrl/todos'),
        headers: headers,
        body: json.encode({'date': dateStr, 'task': task}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          '_id': data['_id'],
          'task': data['task'],
          'done': data['done'],
          'date': data['date'],
        };
      } else {
        print('Create todo error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Create todo exception: $e');
      return null;
    }
  }

  // Update a todo (toggle done or edit task)
  // PATCH /api/todos/:id { task?, done? }
  static Future<Map<String, dynamic>?> updateTodo(String id,
      {String? task, bool? done}) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (task != null) body['task'] = task;
      if (done != null) body['done'] = done;

      final response = await http.patch(
        Uri.parse('$baseUrl/todos/$id'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          '_id': data['_id'],
          'task': data['task'],
          'done': data['done'],
          'date': data['date'],
        };
      } else {
        print('Update todo error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Update todo exception: $e');
      return null;
    }
  }

  // Delete a todo
  // DELETE /api/todos/:id
  static Future<bool> deleteTodo(String id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/todos/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Delete todo error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Delete todo exception: $e');
      return false;
    }
  }
}
