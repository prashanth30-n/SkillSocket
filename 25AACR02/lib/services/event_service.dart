import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EventService {
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

  // Get events for a specific date
  // GET /api/events?date=YYYY-MM-DD
  static Future<List<Map<String, dynamic>>?> getEvents(DateTime date) async {
    try {
      final headers = await _getHeaders();
      final dateStr = _formatDate(date);

      final response = await http.get(
        Uri.parse('$baseUrl/events?date=$dateStr'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => {
                  '_id': item['_id'],
                  'title': item['title'],
                  'date': item['date'],
                })
            .toList();
      } else {
        print('Get events error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Get events exception: $e');
      return null;
    }
  }

  // Create a new event
  // POST /api/events { date: 'YYYY-MM-DD', title: string }
  static Future<Map<String, dynamic>?> createEvent(
      DateTime date, String title) async {
    try {
      final headers = await _getHeaders();
      final dateStr = _formatDate(date);

      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: headers,
        body: json.encode({'date': dateStr, 'title': title}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          '_id': data['_id'],
          'title': data['title'],
          'date': data['date'],
        };
      } else {
        print('Create event error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Create event exception: $e');
      return null;
    }
  }

  // Update an event (edit title)
  // PATCH /api/events/:id { title }
  static Future<Map<String, dynamic>?> updateEvent(
      String id, String title) async {
    try {
      final headers = await _getHeaders();

      final response = await http.patch(
        Uri.parse('$baseUrl/events/$id'),
        headers: headers,
        body: json.encode({'title': title}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          '_id': data['_id'],
          'title': data['title'],
          'date': data['date'],
        };
      } else {
        print('Update event error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Update event exception: $e');
      return null;
    }
  }

  // Delete an event
  // DELETE /api/events/:id
  static Future<bool> deleteEvent(String id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/events/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Delete event error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Delete event exception: $e');
      return false;
    }
  }
}
