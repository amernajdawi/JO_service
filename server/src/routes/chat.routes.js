const express = require('express');
const ChatController = require('../controllers/chat.controller');
const { protectRoute } = require('../middlewares/auth.middleware');

const router = express.Router();

// GET /api/chats/:otherUserId - Get message history with another user
// Requires authentication
router.get('/:otherUserId', protectRoute, ChatController.getChatHistory);

// TODO: Add routes for getting list of conversations, marking messages as read, etc.

module.exports = router; 