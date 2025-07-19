import 'dart:convert';
import 'package:http/http.dart' as http;
import './api_service.dart';

class RatingService {
  final String _baseUrl = '${ApiService.getBaseUrl()}/ratings';

  // Submit a rating for a provider
  Future<void> rateProvider({
    required String token,
    required String bookingId,
    required String providerId,
    required double rating,
    String? review,
  }) async {
    try {
      print('Submitting rating for provider $providerId, booking $bookingId');

      final response = await http.post(
        Uri.parse('$_baseUrl/provider'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'providerId': providerId,
          'bookingId': bookingId,
          'rating': rating,
          'review': review,
        }),
      );

      print('Rating submission response status: ${response.statusCode}');
      print('Rating submission response body: ${response.body}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to submit rating';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error submitting rating: $e');
      throw Exception('Error submitting rating: $e');
    }
  }

  // Check if a user has already rated a booking
  Future<bool> checkIfUserHasRated({
    required String token,
    required String bookingId,
  }) async {
    try {
      print('Checking if user has rated booking $bookingId');

      final response = await http.get(
        Uri.parse('$_baseUrl/check/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Rating check response status: ${response.statusCode}');
      print('Rating check response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['hasRated'] ?? false;
      } else {
        // If the endpoint doesn't exist yet, default to false
        return false;
      }
    } catch (e) {
      print('Error checking if user has rated: $e');
      // Default to false if there's an error
      return false;
    }
  }

  // Get ratings for a provider
  Future<Map<String, dynamic>> getProviderRatings({
    required String token,
    required String providerId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      Uri url = Uri.parse('$_baseUrl/provider/$providerId');

      // Add query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      url = url.replace(queryParameters: queryParams);

      print('Fetching ratings for provider $providerId from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Provider ratings response status: ${response.statusCode}');
      print('Provider ratings response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['message'] ?? 'Failed to get provider ratings';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error getting provider ratings: $e');
      throw Exception('Error getting provider ratings: $e');
    }
  }
}
