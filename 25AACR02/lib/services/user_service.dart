import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'https://skillsocket-backend.onrender.com/api';

  // Helpers used across the app
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Optionally expose token if needed elsewhere
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Internal headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get current user's profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final res =
          await http.get(Uri.parse('$baseUrl/user/profile'), headers: headers);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['user'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Get user profile by ID
  static Future<Map<String, dynamic>?> getUserProfileById(String userId) async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$baseUrl/user/profile/$userId'),
          headers: headers);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['user'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>?> updateUserProfile({
    String? name,
    String? phone,
    String? bio,
    String? location,
    String? dateOfBirth,
    List<String>? skills,
    String? profileImage,
    String? education,
    String? profession,
    String? currentlyWorking,
    List<String>? skillsRequired,
    List<String>? skillsOffered,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (bio != null) body['bio'] = bio;
      if (location != null) body['location'] = location;
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
      if (skills != null) body['skills'] = skills;
      if (profileImage != null) body['profileImage'] = profileImage;
      if (education != null) body['education'] = education;
      if (profession != null) body['profession'] = profession;
      if (currentlyWorking != null) body['currentlyWorking'] = currentlyWorking;
      if (skillsRequired != null) body['skillsRequired'] = skillsRequired;
      if (skillsOffered != null) body['skillsOffered'] = skillsOffered;

      final res = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
        body: json.encode(body),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['user'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Upload user logo (profile image)
  static Future<String?> uploadUserLogo(File logoFile) async {
    try {
      final headers = await _getHeaders();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/upload-logo'),
      );
      // Attach auth header if present
      if (headers['Authorization'] != null) {
        request.headers['Authorization'] = headers['Authorization']!;
      }
      request.files.add(
        await http.MultipartFile.fromPath('logo', logoFile.path),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['logoUrl'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Add a review via user service (compat with existing calls)
  static Future<Map<String, dynamic>?> addReview({
    required String userId,
    required double rating,
    required String title,
    required String comment,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'revieweeId': userId,
        'rating': rating,
        'title': title,
        'comment': comment,
      };
      final res = await http.post(
        Uri.parse('$baseUrl/reviews/add'),
        headers: headers,
        body: json.encode(body),
      );
      if (res.statusCode == 201) {
        return json.decode(res.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
