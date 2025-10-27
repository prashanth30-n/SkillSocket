import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String baseUrl = 'https://skillsocket-backend.onrender.com/api';

  // Get headers with authentication token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get user notifications
  static Future<Map<String, dynamic>?> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/notifications?page=$page&limit=$limit'),
        headers: headers,
      );

      print('Get notifications response: ${response.statusCode}');
      print('Get notifications body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting notifications: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting notifications: $e');
      return null;
    }
  }

  // Mark notifications as read
  static Future<bool> markNotificationsAsRead(
      List<String> notificationIds) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read'),
        headers: headers,
        body: json.encode({
          'notificationIds': notificationIds,
        }),
      );

      print('Mark as read response: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Exception marking notifications as read: $e');
      return false;
    }
  }

  // Get unread count
  static Future<int> getUnreadCount() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Exception getting unread count: $e');
      return 0;
    }
  }

  // Send test notification (for development)
  static Future<bool> sendTestNotification() async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/test'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Exception sending test notification: $e');
      return false;
    }
  }

  // Format notification time
  static String formatNotificationTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  // Get notification icon based on type
  static String getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return '💬';
      case 'connection_request':
        return '🤝';
      case 'connection_accepted':
        return '✅';
      case 'skill_match':
        return '🎯';
      case 'post_like':
        return '❤️';
      case 'post_comment':
        return '💭';
      case 'system':
        return '🔔';
      default:
        return '📢';
    }
  }
}
