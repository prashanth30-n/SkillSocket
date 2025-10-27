import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static const String baseUrl = 'https://skillsocket-backend.onrender.com/api';

  // Get headers with authentication token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print(
        '🔑 ChatService - Retrieved token: ${token != null ? 'Token exists' : 'No token'}');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get current user ID from shared preferences
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Get current user email from shared preferences
  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  // Get user's chats/conversations
  static Future<List<Map<String, dynamic>>?> getUserChats() async {
    try {
      final headers = await _getHeaders();

      print(
          'Making GET request to: $baseUrl/messages/conversations'); // Debug log
      print('With headers: $headers'); // Debug log

      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversations'),
        headers: headers,
      );

      print('Get chats response status: ${response.statusCode}'); // Debug log
      print('Get chats response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['conversations'] ?? []);
      } else {
        print('Get chats error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Get chats exception: $e');
      return [];
    }
  }

  // Get messages for a specific chat/conversation
  static Future<List<Map<String, dynamic>>?> getChatMessages(
      String recipientId) async {
    try {
      final headers = await _getHeaders();

      print(
          'Making GET request to: $baseUrl/messages/$recipientId'); // Debug log
      print('With headers: $headers'); // Debug log

      final response = await http.get(
        Uri.parse('$baseUrl/messages/$recipientId'),
        headers: headers,
      );

      print(
          'Get messages response status: ${response.statusCode}'); // Debug log
      print('Get messages response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['messages'] ?? []);
      } else {
        print('Get messages error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Get messages exception: $e');
      return [];
    }
  }

  // Search for users to start a new chat
  static Future<List<Map<String, dynamic>>?> searchUsers(String query) async {
    try {
      final headers = await _getHeaders();

      print(
          'Making GET request to: $baseUrl/messages/search/users?q=$query'); // Debug log
      print('With headers: $headers'); // Debug log

      final response = await http.get(
        Uri.parse('$baseUrl/messages/search/users?q=$query'),
        headers: headers,
      );

      print(
          'Search users response status: ${response.statusCode}'); // Debug log
      print('Search users response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['users'] ?? []);
      } else {
        print('Search users error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Search users exception: $e');
      return [];
    }
  }

  // Mark messages as read
  static Future<bool> markMessagesAsRead(String partnerId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/messages/mark-seen/$partnerId'),
        headers: headers,
      );

      print(
          'Mark as read response status: ${response.statusCode}'); // Debug log

      return response.statusCode == 200;
    } catch (e) {
      print('Mark as read exception: $e');
      return false;
    }
  }

  // Get unread counts per conversation partner
  static Future<Map<String, int>> getUnreadCounts() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/messages/unread/count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Expected format: [ { _id: senderId, count: N }, ... ]
        final Map<String, int> counts = {};
        if (data is List) {
          for (final item in data) {
            final String? id = (item['_id'] ?? item['id'])?.toString();
            final int count = (item['count'] is int)
                ? item['count']
                : int.tryParse(item['count']?.toString() ?? '0') ?? 0;
            if (id != null) counts[id] = count;
          }
        }
        return counts;
      }
      return {};
    } catch (e) {
      print('Get unread counts exception: $e');
      return {};
    }
  }
}
