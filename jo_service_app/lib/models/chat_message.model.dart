class ChatMessage {
  final String senderId;
  final String senderType; // 'user' or 'provider'
  final String recipientId;
  final String text;
  final DateTime timestamp;
  final bool
      isMe; // Flag to determine if the message was sent by the current user

  ChatMessage({
    required this.senderId,
    required this.senderType,
    required this.recipientId,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  // Factory constructor to parse incoming message data (from WebSocket)
  factory ChatMessage.fromJson(
      Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      senderId: json['senderId'] as String,
      senderType: json['senderType'] as String,
      recipientId: json['recipientId'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isMe: json['senderId'] ==
          currentUserId, // Check if sender is the current user
    );
  }
}
