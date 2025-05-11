const Message = require('../models/message.model');
const mongoose = require('mongoose');

const ChatController = {

    // GET /api/chats/:otherUserId - Get message history with another user
    async getChatHistory(req, res) {
        const currentUserId = req.auth.id; // From protectRoute middleware
        const otherUserId = req.params.otherUserId;

        if (!mongoose.Types.ObjectId.isValid(otherUserId)) {
             return res.status(400).json({ message: 'Invalid user ID format for chat partner.' });
        }
        
        if (currentUserId === otherUserId) {
            return res.status(400).json({ message: 'Cannot fetch chat history with yourself.' });
        }

        try {
            const conversationId = Message.generateConversationId(currentUserId, otherUserId);

            const messages = await Message.find({ conversationId: conversationId })
                                        .sort({ timestamp: 1 }) // Sort by timestamp ascending
                                        .limit(100); // Limit history length for performance
            
            // Optional: Add sender/recipient details by populating if needed, but adds complexity
            // Requires senderType/recipientType to be set correctly in the schema/refs
            // await Message.find(...).populate('senderId', 'fullName profilePictureUrl')... 

            res.status(200).json(messages);

        } catch (error) {
            console.error(`Error fetching chat history between ${currentUserId} and ${otherUserId}:`, error);
            res.status(500).json({ message: 'Failed to fetch chat history', error: error.message });
        }
    }

    // TODO: Add endpoints for managing conversations (e.g., get list of chats, delete chat)
};

module.exports = ChatController; 