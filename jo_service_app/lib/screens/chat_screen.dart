import 'package:flutter/material.dart';
import 'dart:async';
import '../services/chat_service.dart';
import '../models/chat_message.model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const ChatScreen(
      {required this.recipientId, required this.recipientName, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  StreamSubscription? _messageSubscription;
  bool _isConnected = false;
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    final token = await _authService.getToken();
    final currentUserId = await _authService.getUserId();

    if (token == null ||
        token.isEmpty ||
        currentUserId == null ||
        currentUserId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication required.')));
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // 1. Load History
    List<ChatMessage> history = [];
    try {
      history = await _apiService.fetchChatHistory(
          widget.recipientId, token, currentUserId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load chat history: $e')));
      }
      // Continue to connect even if history fails?
    }

    // 2. Connect to WebSocket and listen for new messages
    bool connected = await _chatService.connect(widget.recipientId);

    setState(() {
      _messages = history; // Initialize with history
      _isConnected = connected;
      _isLoading = false;
      _scrollToBottom(); // Scroll after loading history
    });

    if (connected) {
      _messageSubscription = _chatService.messages?.listen((newMessage) {
        setState(() {
          // Avoid adding duplicates if message was already loaded via history (unlikely but possible)
          if (!_messages.any((m) =>
              m.senderId == newMessage.senderId &&
              m.timestamp == newMessage.timestamp &&
              m.text == newMessage.text)) {
            // Filter messages to only include those between current user and recipient
            if (newMessage.recipientId == widget.recipientId ||
                newMessage.senderId == widget.recipientId) {
              _messages.add(newMessage);
              _messages.sort(
                  (a, b) => a.timestamp.compareTo(b.timestamp)); // Ensure order
            }
          }
        });
        _scrollToBottom();
      }, onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Chat error: $error')));
        }
        if (mounted)
          setState(() {
            _isConnected = false;
          });
      }, onDone: () {
        if (mounted)
          setState(() {
            _isConnected = false;
          });
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to connect to chat service.')));
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty && _isConnected) {
      _chatService.sendMessage(
          widget.recipientId, _messageController.text.trim());
      _messageController.clear();
      _scrollToBottom(); // Optimistically scroll
    }
  }

  // Helper to scroll to the bottom of the list
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _chatService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.recipientName}')),
      body: Column(
        children: <Widget>[
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (!_isConnected)
            const Expanded(
                child: Center(
                    child: Text(
                        'Could not connect to chat. Please try again later.')))
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          _buildMessageInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    bool isMe = message.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15.0),
            topRight: const Radius.circular(15.0),
            bottomLeft: isMe ? const Radius.circular(15.0) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(15.0),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              // Format timestamp nicely (requires intl package potentially)
              // For now, just showing time HH:MM
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.black54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration:
          BoxDecoration(color: Theme.of(context).cardColor, boxShadow: const [
        BoxShadow(offset: Offset(0, -1), blurRadius: 1, color: Colors.black12)
      ]),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration.collapsed(
                hintText: 'Send a message...',
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: _sendMessage,
            tooltip: 'Send Message',
          ),
        ],
      ),
    );
  }
}
