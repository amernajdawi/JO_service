import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/provider_model.dart';
import '../models/chat_message.model.dart';
import '../models/user_model.dart';

// New class to model the response from fetching a list of providers
class ProviderListResponse {
  final List<Provider> providers;
  final int currentPage;
  final int totalPages;
  final int totalProviders;

  ProviderListResponse({
    required this.providers,
    required this.currentPage,
    required this.totalPages,
    required this.totalProviders,
  });

  factory ProviderListResponse.fromJson(Map<String, dynamic> json) {
    var providersList = json['providers'] as List;
    List<Provider> providerItems =
        providersList.map((i) => Provider.fromJson(i)).toList();
    return ProviderListResponse(
      providers: providerItems,
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      totalProviders: json['totalProviders'] as int,
    );
  }
}

class ApiService {
  static String getBaseUrl() {
    if (kIsWeb) {
      // Running on the web
      return 'http://localhost:3000/api';
    } else if (Platform.isIOS) {
      // iOS device - use Mac's local network IP
      // If this doesn't work on simulator, change back to localhost
      return 'http://10.46.6.119:3000/api';
    } else {
      // Android emulator
      return 'http://10.0.2.2:3000/api';
    }
  }

  // static const String _baseUrl = 'http://10.0.2.2:3000/api'; // Old static way

  // Updated to accept query parameters and return ProviderListResponse
  Future<ProviderListResponse> fetchProviders(
      Map<String, String>? queryParams) async {
    final String baseUrl = getBaseUrl();
    Uri uri = Uri.parse('$baseUrl/providers');

    // Prepare search parameters
    final Map<String, String> searchParams = queryParams ?? {};

    // If there's a search query, add it with explicit parameters for backend
    if (searchParams.containsKey('search') &&
        searchParams['search']!.isNotEmpty) {
      final searchTerm = searchParams['search']!;

      // Keep the search parameter for backwards compatibility
      // Add a parameter telling the backend to do partial name matching
      searchParams['partialNameMatch'] = 'true';

      print('Searching with partial name match for: $searchTerm');
    }

    // Add category filter if requested
    if (searchParams.containsKey('category') &&
        searchParams['category']!.isNotEmpty) {
      print('Filtering by category: ${searchParams['category']}');
    }

    // Add location filter if requested
    if (searchParams.containsKey('location') &&
        searchParams['location']!.isNotEmpty) {
      final location = searchParams['location']!;
      // Add cityFilter parameter for the backend
      searchParams['cityFilter'] = location;
      print('Filtering by location: $location');
    }

    // Update the URI with all parameters
    uri = uri.replace(queryParameters: searchParams);

    print('Searching providers with URI: $uri');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // The backend returns an object like { providers: [], currentPage: ..., ... }
      return ProviderListResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        'Failed to load providers (Status Code: ${response.statusCode}, Body: ${response.body})',
      );
    }
  }

  Future<Provider> getMyProviderProfile(String token) async {
    final String baseUrl = getBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/providers/profile/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Provider.fromJson(json.decode(response.body));
    } else {
      throw Exception(
          'Failed to load provider profile (Status Code: ${response.statusCode}, Body: ${response.body})');
    }
  }

  Future<Provider> fetchProviderById(String providerId, String token) async {
    final String baseUrl = getBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/providers/$providerId'), // Include providerId in URL
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Send token for protected route
      },
    );

    if (response.statusCode == 200) {
      return Provider.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Provider not found.');
    } else {
      // Handle other errors like 401, 500 etc.
      throw Exception(
          'Failed to load provider details (Status Code: ${response.statusCode}, Body: ${response.body})');
    }
  }

  // New method to update provider's profile
  Future<Provider> updateMyProviderProfile(
      String token, Map<String, dynamic> data) async {
    final String baseUrl = getBaseUrl();
    final response = await http.patch(
      Uri.parse('$baseUrl/providers/profile'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      // The backend returns { message: '...', provider: { ... } }
      final responseData = json.decode(response.body);
      if (responseData['provider'] != null) {
        return Provider.fromJson(responseData['provider']);
      } else {
        throw Exception('Failed to parse provider data from update response.');
      }
    } else {
      throw Exception(
          'Failed to update provider profile (Status Code: ${response.statusCode}, Body: ${response.body})');
    }
  }

  Future<List<ChatMessage>> fetchChatHistory(
      String otherUserId, String token, String currentUserId) async {
    final String baseUrl = getBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/chats/$otherUserId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> messagesJson = json.decode(response.body);
      // Map JSON to ChatMessage objects, passing currentUserId to determine 'isMe' flag
      return messagesJson
          .map((jsonItem) => ChatMessage.fromJson(
              jsonItem as Map<String, dynamic>, currentUserId))
          .toList();
    } else {
      throw Exception(
          'Failed to load chat history (Status Code: ${response.statusCode}, Body: ${response.body})');
    }
  }

  // Delete a specific message
  Future<void> deleteMessage(String messageId, String token) async {
    final String baseUrl = getBaseUrl();
    final response = await http.delete(
      Uri.parse('$baseUrl/chats/messages/$messageId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 
          'Failed to delete message (Status Code: ${response.statusCode})');
    }
  }

  // Add this method to upload profile picture
  Future<Provider?> uploadProfilePicture(String token, File imageFile) async {
    if (kIsWeb) {
      throw Exception(
          'Profile picture upload is not supported on web platform');
    }

    try {
      final String baseUrl = getBaseUrl();
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/providers/profile-picture'),
      );

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'profilePicture',
          imageFile.path,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Provider.fromJson(responseData['provider']);
      } else {
        print(
            'Error uploading profile picture: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to upload profile picture: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in uploadProfilePicture: $e');
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // Add this method to get user profile
  Future<User> getMyUserProfile(String token) async {
    final String baseUrl = getBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception(
          'Failed to load user profile (Status Code: ${response.statusCode}, Body: ${response.body})');
    }
  }

  // Add this method to update user profile
  Future<User> updateMyUserProfile(
      String token, Map<String, dynamic> data) async {
    final String baseUrl = getBaseUrl();
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['user'] != null) {
        return User.fromJson(responseData['user']);
      } else {
        throw Exception('Failed to parse user data from update response.');
      }
    } else {
      throw Exception(
          'Failed to update user profile (Status Code: ${response.statusCode}, Body: ${response.body})');
    }
  }

  // Add this method to upload user profile picture
  Future<User?> uploadUserProfilePicture(String token, File imageFile) async {
    if (kIsWeb) {
      throw Exception(
          'Profile picture upload is not supported on web platform');
    }

    try {
      final String baseUrl = getBaseUrl();
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/me/profile-picture'),
      );

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'profilePicture',
          imageFile.path,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return User.fromJson(responseData['user']);
      } else {
        print(
            'Error uploading profile picture: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to upload profile picture: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in uploadUserProfilePicture: $e');
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // Admin API methods
  
  // Get all providers for admin dashboard
  Future<Map<String, dynamic>> getProvidersForAdmin(String token, {
    int page = 1,
    String? status,
    String? serviceType,
    String? city,
  }) async {
    final String baseUrl = getBaseUrl();
    
    // Build query parameters
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': '50', // Get more providers for admin
    };
    
    if (status != null) queryParams['status'] = status;
    if (serviceType != null) queryParams['serviceType'] = serviceType;
    if (city != null) queryParams['city'] = city;
    
    final uri = Uri.parse('$baseUrl/admin/providers').replace(
      queryParameters: queryParams,
    );
    
    final response = await http.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to fetch providers');
    }
  }

  // Update provider verification status
  Future<Map<String, dynamic>> updateProviderStatus(
    String token,
    String providerId,
    String status, {
    String? rejectionReason,
  }) async {
    final String baseUrl = getBaseUrl();
    
    final requestBody = {
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/admin/providers/$providerId/status'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to update provider status');
    }
  }

  // Admin login
  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    final String baseUrl = getBaseUrl();
    
    final response = await http.post(
      Uri.parse('$baseUrl/admin/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Admin login failed');
    }
  }

  // Get admin dashboard statistics
  Future<Map<String, dynamic>> getAdminDashboardStats(String token) async {
    final String baseUrl = getBaseUrl();
    
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard/stats'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to fetch dashboard stats');
    }
  }
}
