const express = require('express');
const router = express.Router();
const NotificationService = require('../services/notificationService');
const verifyToken = require('../middlewares/verifyToken');

// GET /api/notifications - Get user notifications
router.get('/', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { page = 1, limit = 20 } = req.query;

        const result = await NotificationService.getUserNotifications(
            userId, 
            parseInt(page), 
            parseInt(limit)
        );

        res.json({
            success: true,
            data: result.notifications,
            unreadCount: result.unreadCount,
            hasMore: result.hasMore,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit)
            }
        });

    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

// PUT /api/notifications/read - Mark notifications as read
router.put('/read', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { notificationIds } = req.body;

        if (!notificationIds || !Array.isArray(notificationIds)) {
            return res.status(400).json({
                success: false,
                message: 'notificationIds array is required'
            });
        }

        await NotificationService.markAsRead(notificationIds, userId);

        res.json({
            success: true,
            message: 'Notifications marked as read'
        });

    } catch (error) {
        console.error('Error marking notifications as read:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

// GET /api/notifications/unread-count - Get unread count
router.get('/unread-count', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        
        const result = await NotificationService.getUserNotifications(userId, 1, 1);

        res.json({
            success: true,
            unreadCount: result.unreadCount
        });

    } catch (error) {
        console.error('Error fetching unread count:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

// POST /api/notifications/test - Test notification (development only)
router.post('/test', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        
        await NotificationService.createNotification({
            recipientId: userId,
            type: 'system',
            title: 'Test Notification',
            body: 'This is a test notification from the system',
            data: { test: true }
        });

        res.json({
            success: true,
            message: 'Test notification sent'
        });

    } catch (error) {
        console.error('Error sending test notification:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

module.exports = router;
