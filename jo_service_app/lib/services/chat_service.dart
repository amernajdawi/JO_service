import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.model.dart';
import './auth_service.dart';

class ChatService {
  final AuthService _authService = AuthService();
  WebSocketChannel? _channel;
  StreamController<ChatMessage>? _messageController;
  String? _currentUserId;

  // Public stream for UI to listen to
  Stream<ChatMessage>? get messages => _messageController?.stream;

  Future<bool> connect(String recipientId) async {
    disconnect(); // Ensure any previous connection is closed
    _messageController = StreamController<ChatMessage>.broadcast();

    final token = await _authService.getToken();
    _currentUserId = await _authService.getUserId();

    print('ChatService: token length: ${token?.length ?? 0}');
    print('ChatService: currentUserId: $_currentUserId');

    if (token == null || token.isEmpty || _currentUserId == null) {
      print('ChatService Error: Not authenticated. Token: ${token != null ? 'present' : 'null'}, UserId: ${_currentUserId != null ? 'present' : 'null'}');
      _messageController
          ?.addError('Authentication required to connect to chat.');
      return false;
    }

    // Determine WebSocket URL based on platform
    String wsBaseUrl;
    if (kIsWeb) {
      wsBaseUrl = 'ws://localhost:3000'; // Use ws:// for web
    } else if (Platform.isIOS) {
      // iOS device or simulator - use Mac's IP address
      wsBaseUrl = 'ws://10.46.6.119:3000';
    } else {
      // Android emulator
      wsBaseUrl = 'ws://10.0.2.2:3000';
    }

    final url =
        Uri.parse('$wsBaseUrl?token=$token'); // Pass token as query param

    print('Connecting to WebSocket: $url');
    try {
      _channel = WebSocketChannel.connect(url);
      print('WebSocket Connected.');

      _channel!.stream.listen(
        (data) {
          try {
            print('Raw WS Data Received: $data');
            final decoded = json.decode(data as String);
            if (decoded is Map<String, dynamic>) {
              if (decoded['type'] == 'message' && decoded['data'] != null) {
                final messageData = decoded['data'] as Map<String, dynamic>;
                // Ensure message is relevant to this chat (either sender or recipient matches current user)
                if (messageData['senderId'] == _currentUserId ||
                    messageData['recipientId'] == _currentUserId) {
                  final message =
                      ChatMessage.fromJson(messageData, _currentUserId!);
                  _messageController?.add(message);
                }
              } else if (decoded['type'] == 'info' ||
                  decoded['type'] == 'error') {
                print('Chat Info/Error: ${decoded['message']}');
                // Optionally expose these info/error messages via another stream if needed by UI
              }
            }
          } catch (e) {
            print('Error parsing WebSocket message: $e');
            _messageController?.addError('Error parsing message: $e');
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _messageController?.addError(error);
          disconnect();
        },
        onDone: () {
          print('WebSocket Disconnected.');
          _messageController?.close();
          _channel = null;
        },
      );
      return true;
    } catch (e) {
      print('WebSocket connection error: $e');
      _messageController?.addError('Failed to connect: $e');
      disconnect(); // Clean up controller if connection fails
      return false;
    }
  }

  void sendMessage(String recipientId, String text) {
    if (_channel != null && _currentUserId != null) {
      final message = jsonEncode({
        'recipientId': recipientId,
        'text': text,
      });
      print('Sending message: $message');
      _channel!.sink.add(message);
    } else {
      print(
          'Cannot send message: WebSocket not connected or user not authenticated.');
      // Optionally notify UI about the failure
    }
  }

  void disconnect() {
    print('Disconnecting WebSocket...');
    _channel?.sink.close();
    _messageController?.close();
    _channel = null;
    _messageController = null;
    _currentUserId = null;
  }
}
