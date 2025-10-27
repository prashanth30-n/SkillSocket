import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionService {
  static const String baseUrl = 'https://skillsocket-backend.onrender.com/api/connections';

  // Get headers with authentication token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Send connection request
  static Future<Map<String, dynamic>?> sendConnectionRequest({
    required String toUserId,
    String? message,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: headers,
        body: jsonEncode({
          'toUserId': toUserId,
          'message': message ?? 'Would like to connect with you!',
        }),
      );

      print('Send connection request response: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Parse response body for both success and error cases
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Success case
        return {
          'success': true,
          'message': data['message'] ?? 'Connection request sent successfully',
          'data': data['data']
        };
      } else {
        // Error case - return the error details from backend
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send connection request',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('Exception sending connection request: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please try again.',
        'error': e.toString()
      };
    }
  }

  // Get received connection requests (for notifications)
  static Future<List<Map<String, dynamic>>?> getReceivedRequests() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/received'),
        headers: headers,
      );

      print('Get received requests response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Exception getting received requests: $e');
      return [];
    }
  }

  // Accept connection request
  static Future<bool> acceptConnectionRequest(String requestId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/accept/$requestId'),
        headers: headers,
      );

      print('Accept request response: ${response.statusCode}');

      // Try to parse body if present
      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 200) {
        return (data != null ? (data['success'] == true) : true);
      }

      // Treat idempotent responses as success (already accepted/handled)
      final msg = (data != null
          ? (data['message']?.toString().toLowerCase() ?? '')
          : '');
      if (response.statusCode == 400 ||
          response.statusCode == 409 ||
          response.statusCode == 404) {
        if (msg.contains('already') ||
            msg.contains('handled') ||
            msg.contains('accepted')) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Exception accepting request: $e');
      return false;
    }
  }

  // Reject connection request
  static Future<bool> rejectConnectionRequest(String requestId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/reject/$requestId'),
        headers: headers,
      );

      print('Reject request response: ${response.statusCode}');

      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 200) {
        return (data != null ? (data['success'] == true) : true);
      }

      // Treat idempotent responses as success (already rejected/handled)
      final msg = (data != null
          ? (data['message']?.toString().toLowerCase() ?? '')
          : '');
      if (response.statusCode == 400 ||
          response.statusCode == 409 ||
          response.statusCode == 404) {
        if (msg.contains('already') ||
            msg.contains('handled') ||
            msg.contains('rejected')) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Exception rejecting request: $e');
      return false;
    }
  }

  // Get sent connection requests
  static Future<List<Map<String, dynamic>>?> getSentRequests() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/sent'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Exception getting sent requests: $e');
      return [];
    }
  }
}
