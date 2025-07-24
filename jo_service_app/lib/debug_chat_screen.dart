import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'models/chat_message.model.dart';

class DebugChatScreen extends StatefulWidget {
  @override
  _DebugChatScreenState createState() => _DebugChatScreenState();
}

class _DebugChatScreenState extends State<DebugChatScreen> {
  final _recipientIdController = TextEditingController();
  final _messageController = TextEditingController();
  final _debugLogs = <String>[];
  late AuthService _authService;
  ChatService? _chatService;
  String? _currentUserId;
  String? _token;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _initializeDebug();
  }

  void _initializeDebug() async {
    _token = await _authService.getToken();
    _currentUserId = await _authService.getUserId();
    _addLog('🔐 Current User ID: $_currentUserId');
    _addLog('🔑 Token length: ${_token?.length ?? 0}');
  }

  void _addLog(String message) {
    setState(() {
      _debugLogs.insert(0, '[${DateTime.now().toString()}] $message');
      // Keep only last 50 logs
      if (_debugLogs.length > 50) {
        _debugLogs.removeLast();
      }
    });
  }

  void _connectToChat() async {
    if (_recipientIdController.text.isEmpty) {
      _addLog('❌ Please enter a recipient ID');
      return;
    }

    _chatService = ChatService(_authService);
    _addLog('🔌 Attempting to connect to WebSocket...');
    
    bool connected = await _chatService!.connect(_recipientIdController.text);
    setState(() {
      _isConnected = connected;
    });

    if (connected) {
      _addLog('✅ Connected to WebSocket');
      _chatService!.messages?.listen(
        (message) {
          _addLog('📥 Received: "${message.text}" from ${message.senderId}');
        },
        onError: (error) {
          _addLog('❌ Stream Error: $error');
        },
      );
    } else {
      _addLog('❌ Failed to connect to WebSocket');
    }
  }

  void _sendTestMessage() {
    if (!_isConnected || _chatService == null) {
      _addLog('❌ Not connected to chat service');
      return;
    }

    if (_messageController.text.isEmpty) {
      _addLog('❌ Please enter a message');
      return;
    }

    _addLog('📤 Sending: "${_messageController.text}" to ${_recipientIdController.text}');
    _chatService!.sendMessage(_recipientIdController.text, _messageController.text);
    _messageController.clear();
  }

  void _disconnect() {
    if (_chatService != null) {
      _chatService!.disconnect();
      _addLog('🔌 Disconnected from WebSocket');
      setState(() {
        _isConnected = false;
      });
    }
  }

  void _clearLogs() {
    setState(() {
      _debugLogs.clear();
    });
  }

  @override
  void dispose() {
    _chatService?.disconnect();
    _recipientIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Debug Tool'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isConnected ? '✅ Connected' : '❌ Not Connected',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isConnected ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Recipient ID Input
            TextField(
              controller: _recipientIdController,
              decoration: InputDecoration(
                labelText: 'Recipient ID',
                hintText: 'Enter the recipient\'s user ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            
            // Connect/Disconnect Button
            ElevatedButton(
              onPressed: _isConnected ? _disconnect : _connectToChat,
              child: Text(_isConnected ? 'Disconnect' : 'Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isConnected ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            
            // Message Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Test Message',
                      hintText: 'Enter a test message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isConnected ? _sendTestMessage : null,
                  child: Text('Send'),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Debug Logs
            Text(
              'Debug Logs:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: ListView.builder(
                  itemCount: _debugLogs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _debugLogs[index],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
