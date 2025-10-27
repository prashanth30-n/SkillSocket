import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PostService {
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

  // Get headers for multipart requests
  static Future<Map<String, String>> _getMultipartHeaders() async {
    final token = await _getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Create a new post
  static Future<Map<String, dynamic>?> createPost({
    required String content,
    File? imageFile,
  }) async {
    try {
      final headers = await _getMultipartHeaders();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/posts'),
      );

      request.headers.addAll(headers);
      request.fields['content'] = content;

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Create post error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Create post exception: $e');
      return null;
    }
  }

  // Get posts with pagination and search
  static Future<Map<String, dynamic>?> getPosts({
    int page = 1,
    int limit = 10,
    String? search,
    String? userId,
  }) async {
    try {
      final headers = await _getHeaders();

      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (userId != null) {
        queryParams['user'] = userId;
      }

      final uri =
          Uri.parse('$baseUrl/posts').replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Get posts error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Get posts exception: $e');
      return null;
    }
  }

  // Get single post by ID
  static Future<Map<String, dynamic>?> getPost(String postId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Get post error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Get post exception: $e');
      return null;
    }
  }

  // Toggle like on a post
  static Future<Map<String, dynamic>?> toggleLike(String postId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Toggle like error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Toggle like exception: $e');
      return null;
    }
  }

  // Add comment to a post
  static Future<List<dynamic>?> addComment(
      String postId, String content) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comment'),
        headers: headers,
        body: json.encode({'text': content}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Add comment error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Add comment exception: $e');
      return null;
    }
  }

  // Delete a post (owner only)
  static Future<bool> deletePost(String postId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Delete post error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Delete post exception: $e');
      return false;
    }
  }
}
