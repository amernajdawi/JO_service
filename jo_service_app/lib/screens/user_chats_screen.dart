import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../models/booking_model.dart';
import '../models/chat_conversation.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class UserChatsScreen extends StatefulWidget {
  const UserChatsScreen({super.key});

  @override
  State<UserChatsScreen> createState() => _UserChatsScreenState();
}

class _UserChatsScreenState extends State<UserChatsScreen> {
  final BookingService _bookingService = BookingService();
  late final AuthService _authService;
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadConversations();
  }

  void _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      final userId = await _authService.getUserId();
      _currentUserId = userId;

      if (token != null && userId != null) {
        // Load conversations from bookings (temporary solution)
        final bookingsMap = await _bookingService.getUserBookings(token: token);
        final bookings = bookingsMap['bookings'] ?? [];
        
        // Convert bookings to conversations with improved UI
        final conversations = <ChatConversation>[];
        final seenParticipants = <String>{};
        
        for (final booking in bookings) {
          if (booking is Booking && booking.provider != null) {
            final providerId = booking.provider!.id??'';
            
            // Avoid duplicate conversations with the same provider
            if (!seenParticipants.contains(providerId)) {
              seenParticipants.add(providerId);
              
              final conversation = ChatConversation(
                id: booking.id,
                participantId: providerId,
                participantName: booking.provider!.fullName ?? 'Provider',
                participantAvatar: booking.provider!.profilePictureUrl,
                participantType: 'provider',
                lastMessage: _getLastMessagePreview(booking),
                lastMessageTime: booking.updatedAt ?? booking.createdAt,
                isOnline: false,
                unreadCount: 0,
              );
              
              conversations.add(conversation);
            }
          }
        }
        
        // Sort conversations by last message time (most recent first)
        conversations.sort((a, b) {
          if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
          if (a.lastMessageTime == null) return 1;
          if (b.lastMessageTime == null) return -1;
          return b.lastMessageTime!.compareTo(a.lastMessageTime!);
        });
        
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication required')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chats: $e')),
        );
      }
    }
  }

  String _getLastMessagePreview(Booking booking) {
    switch (booking.status) {
      case 'pending':
        return 'Booking request sent - waiting for response';
      case 'accepted':
        return 'Booking confirmed! Start chatting to coordinate';
      case 'in_progress':
        return 'Service in progress';
      case 'completed':
        return 'Service completed - How was your experience?';
      case 'declined_by_provider':
        return 'Booking declined by provider';
      case 'cancelled_by_user':
        return 'Booking cancelled';
      default:
        return 'Tap to start chatting';
    }
  }

  void _openChat(ChatConversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No chats yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Book a service to start chatting with providers',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadConversations();
                  },
                  child: ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildChatListItem(conversation);
                    },
                  ),
                ),
    );
  }

  Widget _buildChatListItem(ChatConversation conversation) {
    return InkWell(
      onTap: () => _openChat(conversation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Profile Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: conversation.participantAvatar != null
                      ? Colors.transparent
                      : Theme.of(context).primaryColor,
                  backgroundImage: conversation.participantAvatar != null
                      ? NetworkImage(conversation.participantAvatar!)
                      : null,
                  child: conversation.participantAvatar == null
                      ? Text(
                          conversation.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                // Online indicator
                if (conversation.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Chat Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Time Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.participantName,
                          style: TextStyle(
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        conversation.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: conversation.unreadCount > 0
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Last Message and Unread Count Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? 'Tap to start chatting',
                          style: TextStyle(
                            fontSize: 14,
                            color: conversation.unreadCount > 0
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Unread count badge
                      if (conversation.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
