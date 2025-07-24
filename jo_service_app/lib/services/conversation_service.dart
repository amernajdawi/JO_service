import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/chat_conversation.dart';

class ConversationService {
  static String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (Platform.isIOS) {
      return 'http://10.46.6.119:3000'; // IMPORTANT: Replace with your Mac's local IP
    } else {
      return 'http://10.0.2.2:3000';
    }
  }

  static String get baseImageUrl => getBaseUrl();
  static String get apiUrl => '${getBaseUrl()}/api';

  // Get all conversations for the current user
  Future<List<ChatConversation>> getConversations({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('ConversationService: Response status: ${response.statusCode}');
      print('ConversationService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final conversationsData = data['conversations'] as List;
        
        print('DEBUG: Raw conversations data from backend:');
        for (var conv in conversationsData) {
          print('DEBUG: Conversation: ${conv['id']}, booking: ${conv['booking']}, photos: ${conv['booking']?['photos']}');
        }
        
        return conversationsData
            .map((conv) => ChatConversation.fromJson(conv))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load conversations');
      }
    } catch (e) {
      print('ConversationService Error: $e');
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused')) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  // Mark messages as read (for future implementation)
  Future<void> markAsRead({
    required String token,
    required String conversationId,
  }) async {
    // TODO: Implement when backend endpoint is available
    print('ConversationService: markAsRead called for conversation $conversationId');
  }

  // Delete conversation (for future implementation)
  Future<void> deleteConversation({
    required String token,
    required String conversationId,
  }) async {
    // TODO: Implement when backend endpoint is available
    print('ConversationService: deleteConversation called for conversation $conversationId');
  }
}
