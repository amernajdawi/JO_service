import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/provider_model.dart';
import '../models/chat_message.model.dart';

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
    } else {
      // Assuming Android emulator for non-web, adjust if necessary for iOS sim or physical devices
      return 'http://10.0.2.2:3000/api';
    }
  }

  // static const String _baseUrl = 'http://10.0.2.2:3000/api'; // Old static way

  // Updated to accept query parameters and return ProviderListResponse
  Future<ProviderListResponse> fetchProviders(
      Map<String, String>? queryParams) async {
    final String baseUrl = getBaseUrl();
    Uri uri = Uri.parse('$baseUrl/providers');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

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
      Uri.parse('$baseUrl/providers/me'),
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
    final response = await http.put(
      Uri.parse('$baseUrl/providers/me'),
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
}
