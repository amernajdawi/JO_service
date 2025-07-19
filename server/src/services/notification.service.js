const Notification = require('../models/notification.model');
const WebSocketService = require('./websocket.service');

class NotificationService {
    /**
     * Create a new notification
     * @param {Object} notificationData - The notification data
     * @returns {Promise<Object>} - The created notification
     */
    static async createNotification(notificationData) {
        try {
            const notification = new Notification(notificationData);
            const savedNotification = await notification.save();
            
            // Send real-time notification via WebSocket if available
            try {
                const wsPayload = {
                    type: 'notification',
                    data: savedNotification
                };
                
                WebSocketService.sendToUser(
                    notificationData.recipient.toString(), 
                    notificationData.recipientModel,
                    wsPayload
                );
            } catch (wsError) {
                console.error('Error sending WebSocket notification:', wsError);
                // Continue even if WebSocket fails - user will still see notification on next login
            }
            
            return savedNotification;
        } catch (error) {
            console.error('Error creating notification:', error);
            throw error;
        }
    }

    /**
     * Send booking status notification to both user and provider
     * @param {Object} booking - The booking object (populated with user and provider)
     * @param {String} status - The new status
     * @param {String} actorType - The type of user who performed the action ('user' or 'provider')
     */
    static async sendBookingStatusNotification(booking, status, actorType) {
        try {
            const userId = booking.user._id;
            const providerId = booking.provider._id;
            const userFullName = booking.user.fullName || 'User';
            const providerFullName = booking.provider.fullName || 'Provider';
            const serviceType = booking.provider.serviceType || 'service';
            const dateTime = new Date(booking.serviceDateTime).toLocaleString();
            
            let userNotification, providerNotification;
            
            switch (status) {
                case 'pending':
                    // New booking created (send to provider only)
                    providerNotification = {
                        recipient: providerId,
                        recipientModel: 'Provider',
                        type: 'booking_created',
                        title: 'New Booking Request',
                        message: `${userFullName} has requested your ${serviceType} services on ${dateTime}.`,
                        relatedBooking: booking._id
                    };
                    break;
                    
                case 'accepted':
                    // Booking accepted (send to user only)
                    userNotification = {
                        recipient: userId,
                        recipientModel: 'User',
                        type: 'booking_accepted',
                        title: 'Booking Accepted',
                        message: `${providerFullName} has accepted your booking for ${serviceType} on ${dateTime}.`,
                        relatedBooking: booking._id
                    };
                    break;
                    
                case 'declined_by_provider':
                    // Booking declined (send to user only)
                    userNotification = {
                        recipient: userId,
                        recipientModel: 'User',
                        type: 'booking_declined',
                        title: 'Booking Declined',
                        message: `${providerFullName} has declined your booking for ${serviceType} on ${dateTime}.`,
                        relatedBooking: booking._id
                    };
                    break;
                    
                case 'cancelled_by_user':
                    // Booking cancelled (send to provider only)
                    providerNotification = {
                        recipient: providerId,
                        recipientModel: 'Provider',
                        type: 'booking_cancelled',
                        title: 'Booking Cancelled',
                        message: `${userFullName} has cancelled their booking for your ${serviceType} on ${dateTime}.`,
                        relatedBooking: booking._id
                    };
                    break;
                    
                case 'in_progress':
                    // Service started (send to user only)
                    userNotification = {
                        recipient: userId,
                        recipientModel: 'User',
                        type: 'booking_in_progress',
                        title: 'Service Started',
                        message: `${providerFullName} has started their ${serviceType} service for your booking.`,
                        relatedBooking: booking._id
                    };
                    break;
                    
                case 'completed':
                    // Service completed (send to user only)
                    userNotification = {
                        recipient: userId,
                        recipientModel: 'User',
                        type: 'booking_completed',
                        title: 'Service Completed',
                        message: `${providerFullName} has completed their ${serviceType} service. Please rate your experience!`,
                        relatedBooking: booking._id
                    };
                    break;
            }
            
            // Send notifications
            const promises = [];
            if (userNotification) {
                promises.push(this.createNotification(userNotification));
            }
            if (providerNotification) {
                promises.push(this.createNotification(providerNotification));
            }
            
            await Promise.all(promises);
        } catch (error) {
            console.error('Error sending booking status notification:', error);
            // Don't throw the error to prevent blocking the main booking process
        }
    }

    /**
     * Mark a notification as read
     * @param {String} notificationId - The notification ID
     */
    static async markAsRead(notificationId) {
        try {
            return await Notification.findByIdAndUpdate(
                notificationId,
                { isRead: true },
                { new: true }
            );
        } catch (error) {
            console.error('Error marking notification as read:', error);
            throw error;
        }
    }

    /**
     * Mark all notifications as read for a user
     * @param {String} userId - The user ID
     * @param {String} userType - The user type ('User' or 'Provider')
     */
    static async markAllAsRead(userId, userType) {
        try {
            return await Notification.updateMany(
                { recipient: userId, recipientModel: userType, isRead: false },
                { isRead: true }
            );
        } catch (error) {
            console.error('Error marking all notifications as read:', error);
            throw error;
        }
    }

    /**
     * Get notifications for a user
     * @param {String} userId - The user ID
     * @param {String} userType - The user type ('User' or 'Provider')
     * @param {Object} options - Additional options (limit, offset, unreadOnly)
     */
    static async getUserNotifications(userId, userType, options = {}) {
        try {
            const { limit = 20, page = 1, unreadOnly = false } = options;
            const skip = (page - 1) * limit;
            
            const query = { 
                recipient: userId, 
                recipientModel: userType 
            };
            
            if (unreadOnly) {
                query.isRead = false;
            }
            
            const [notifications, total] = await Promise.all([
                Notification.find(query)
                    .sort({ createdAt: -1 })
                    .skip(skip)
                    .limit(limit)
                    .populate('relatedBooking', 'serviceDateTime status')
                    .lean(),
                Notification.countDocuments(query)
            ]);
            
            return {
                notifications,
                total,
                unreadCount: unreadOnly ? total : await Notification.countDocuments({
                    ...query,
                    isRead: false
                }),
                page,
                totalPages: Math.ceil(total / limit)
            };
        } catch (error) {
            console.error('Error getting user notifications:', error);
            throw error;
        }
    }
}

module.exports = NotificationService; 