import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  // Like a review
  static Future<Map<String, dynamic>?> likeReview(String reviewId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/like/$reviewId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Exception liking review: $e');
    }
    return null;
  }

  // Dislike a review
  static Future<Map<String, dynamic>?> dislikeReview(String reviewId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/dislike/$reviewId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Exception disliking review: $e');
    }
    return null;
  }
  // Base URL for the review API

  static const String baseUrl =
      'https://skillsocket-backend.onrender.com/api/reviews';

  // Get headers with authentication token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Add a review
  static Future<Map<String, dynamic>?> addReview({
    required String revieweeId,
    required double rating,
    required String title,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: headers,
        body: jsonEncode({
          'revieweeId': revieweeId,
          'rating': rating,
          'title': title,
        }),
      );

      print('Add review response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Error adding review: ${response.statusCode} - ${response.body}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to add review'
        };
      }
    } catch (e) {
      print('Exception adding review: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Get reviews for a user
  static Future<Map<String, dynamic>?> getUserReviews({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId?page=$page&limit=$limit'),
        headers: headers,
      );

      print('Get user reviews response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Exception getting user reviews: $e');
      return null;
    }
  }

  // Get reviews written by current user
  static Future<List<Map<String, dynamic>>?> getMyReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        print('No user ID found');
        return null;
      }

      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/by-user/$userId'),
        headers: headers,
      );

      print('Get my reviews response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Exception getting my reviews: $e');
      return [];
    }
  }

  // Update a review
  static Future<Map<String, dynamic>?> updateReview({
    required String reviewId,
    double? rating,
    String? title,
  }) async {
    try {
      final headers = await _getHeaders();

      final body = <String, dynamic>{};
      if (rating != null) body['rating'] = rating;
      if (title != null) body['title'] = title;

      final response = await http.put(
        Uri.parse('$baseUrl/update/$reviewId'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Update review response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update review'
        };
      }
    } catch (e) {
      print('Exception updating review: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Delete a review
  static Future<bool> deleteReview(String reviewId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$reviewId'),
        headers: headers,
      );

      print('Delete review response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Exception deleting review: $e');
      return false;
    }
  }

  // Helper method to format rating display
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  // Helper method to get star display
  static String getStarDisplay(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    String stars = '★' * fullStars;
    if (hasHalfStar) stars += '☆';

    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    stars += '☆' * emptyStars;

    return stars;
  }
}
