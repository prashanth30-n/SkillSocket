const Notification = require('../models/Notification');
const User = require('../models/User');

class NotificationService {
    
    // Create and send notification
    static async createNotification({
        recipientId,
        senderId = null,
        type,
        title,
        body,
        data = {}
    }) {
        try {
            // Create notification in database
            const notification = new Notification({
                recipient: recipientId,
                sender: senderId,
                type,
                title,
                body,
                data
            });

            await notification.save();

            // Populate sender info for real-time emission
            const populatedNotification = await Notification.findById(notification._id)
                .populate('sender', 'name profileImage')
                .populate('recipient', 'name');

            // Send real-time notification via Socket.IO
            const io = require('../server').io; // We'll need to export io from server.js
            if (io) {
                io.to(recipientId).emit('newNotification', {
                    id: notification._id,
                    type,
                    title,
                    body,
                    data,
                    sender: populatedNotification.sender,
                    createdAt: notification.createdAt,
                    read: false
                });
            }

            // TODO: Send push notification (FCM)
            await this.sendPushNotification(recipientId, title, body, data);

            return notification;
        } catch (error) {
            console.error('Error creating notification:', error);
            throw error;
        }
    }

    // Send push notification via FCM
    static async sendPushNotification(userId, title, body, data) {
        try {
            // Get user's FCM token from database
            const user = await User.findById(userId).select('fcmToken');
            
            if (!user || !user.fcmToken) {
                console.log(`No FCM token found for user ${userId}`);
                return;
            }

            // Import Firebase Admin SDK
            const { admin, isInitialized } = require('../config/firebase');
            
            if (!isInitialized()) {
                console.log('📱 Firebase not initialized, skipping push notification');
                return;
            }

            // Prepare FCM message
            const message = {
                notification: {
                    title,
                    body
                },
                data: {
                    // Convert all data values to strings (FCM requirement)
                    ...Object.keys(data).reduce((acc, key) => {
                        acc[key] = String(data[key]);
                        return acc;
                    }, {}),
                    click_action: 'FLUTTER_NOTIFICATION_CLICK'
                },
                token: user.fcmToken,
                android: {
                    notification: {
                        channelId: 'skillsocket_channel',
                        priority: 'high',
                        defaultSound: true,
                        defaultVibrateTimings: true
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1
                        }
                    }
                }
            };

            // Send the message
            const response = await admin.messaging().send(message);
            console.log(`📱 Push notification sent successfully to ${userId}:`, response);
            
        } catch (error) {
            if (error.code === 'messaging/registration-token-not-registered') {
                console.log(`FCM token invalid for user ${userId}, removing from database`);
                // Remove invalid token from database
                await User.findByIdAndUpdate(userId, { $unset: { fcmToken: 1 } });
            } else {
                console.error('Error sending push notification:', error);
            }
        }
    }

    // Notification helpers for different types
    static async notifyNewMessage(senderId, recipientId, messageContent, chatId) {
        const sender = await User.findById(senderId).select('name');
        
        // For messages, we ONLY send push notifications (not in-app notifications)
        // This matches WhatsApp behavior - messages don't appear in notifications tab
        
        // Only send push notification, don't store in database for notifications tab
        await this.sendPushNotification(
            recipientId, 
            `New message from ${sender.name}`,
            messageContent.length > 50 ? messageContent.substring(0, 50) + '...' : messageContent,
            { chatId, senderId, type: 'message' }
        );
        
        // Don't return a notification object since we're not storing it
        return null;
    }

    static async notifyConnectionRequest(senderId, recipientId, requestId) {
        const sender = await User.findById(senderId).select('name');
        
        return await this.createNotification({
            recipientId,
            senderId,
            type: 'connection_request',
            title: 'New Connection Request',
            body: `${sender.name} wants to connect with you`,
            data: { requestId, senderId }
        });
    }

    static async notifyConnectionAccepted(senderId, recipientId) {
        const sender = await User.findById(senderId).select('name');
        
        return await this.createNotification({
            recipientId,
            senderId,
            type: 'connection_accepted',
            title: 'Connection Accepted',
            body: `${sender.name} accepted your connection request`,
            data: { senderId }
        });
    }

    static async notifySkillMatch(userId, matchedUserId) {
        const matchedUser = await User.findById(matchedUserId).select('name');
        
        return await this.createNotification({
            recipientId: userId,
            type: 'skill_match',
            title: 'New Skill Match!',
            body: `You have a skill match with ${matchedUser.name}`,
            data: { matchedUserId }
        });
    }

    // Mark notifications as read
    static async markAsRead(notificationIds, userId) {
        return await Notification.updateMany(
            { 
                _id: { $in: notificationIds },
                recipient: userId 
            },
            { read: true }
        );
    }

    // Get user notifications
    static async getUserNotifications(userId, page = 1, limit = 20) {
        const skip = (page - 1) * limit;
        
        const notifications = await Notification.find({ recipient: userId })
            .populate('sender', 'name profileImage')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        const unreadCount = await Notification.countDocuments({
            recipient: userId,
            read: false
        });

        return {
            notifications,
            unreadCount,
            hasMore: notifications.length === limit
        };
    }
}

module.exports = NotificationService;
