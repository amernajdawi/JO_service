const express = require('express');
const NotificationController = require('../controllers/notification.controller');
const { protectRoute } = require('../middlewares/auth.middleware');

const router = express.Router();

// All notification routes require authentication
router.use(protectRoute);

// GET /api/notifications - Get notifications for the logged-in user
router.get('/', NotificationController.getNotifications);

// GET /api/notifications/unread-count - Get the count of unread notifications
router.get('/unread-count', NotificationController.getUnreadCount);

// PATCH /api/notifications/:id/read - Mark a notification as read
router.patch('/:id/read', NotificationController.markAsRead);

// PATCH /api/notifications/read-all - Mark all notifications as read
router.patch('/read-all', NotificationController.markAllAsRead);

module.exports = router; 