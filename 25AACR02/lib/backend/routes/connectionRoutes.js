const express = require('express');
const router = express.Router();
const ConnectionRequest = require('../models/ConnectionRequest');
const NotificationService = require('../services/notificationService');
const verifyToken = require('../middlewares/verifyToken');

// Send connection request
router.post('/send', verifyToken, async (req, res) => {
    try {
        const fromUserId = req.user.userId;
        const { toUserId, message } = req.body;

        // Validate required fields
        if (!toUserId) {
            return res.status(400).json({ 
                success: false, 
                message: 'toUserId is required' 
            });
        }

        // Check if request already exists and is still pending
        const existingRequest = await ConnectionRequest.findOne({
            from: fromUserId,
            to: toUserId,
            status: 'pending'
        });

        if (existingRequest) {
            return res.status(400).json({ 
                success: false, 
                message: 'Connection request already sent' 
            });
        }

        // Check if there's an accepted connection (they're already connected)
        const acceptedRequest = await ConnectionRequest.findOne({
            $or: [
                { from: fromUserId, to: toUserId, status: 'accepted' },
                { from: toUserId, to: fromUserId, status: 'accepted' }
            ]
        });

        if (acceptedRequest) {
            return res.status(400).json({ 
                success: false, 
                message: 'You are already connected with this user' 
            });
        }

        // Don't allow self-requests
        if (fromUserId === toUserId) {
            return res.status(400).json({ 
                success: false, 
                message: 'Cannot send request to yourself' 
            });
        }

        // Create new connection request
        const connectionRequest = new ConnectionRequest({
            from: fromUserId,
            to: toUserId,
            message: message || 'Would like to connect with you!'
        });

        await connectionRequest.save();

        // Populate the request with user details
        const populatedRequest = await ConnectionRequest.findById(connectionRequest._id)
            .populate('from', 'name profileImage logo email')
            .populate('to', 'name profileImage logo email');//populate is just like the join operation

        // Send notification to recipient
        await NotificationService.notifyConnectionRequest(fromUserId, toUserId, connectionRequest._id);

        res.status(201).json({
            success: true,
            message: 'Connection request sent successfully',
            data: populatedRequest
        });

    } catch (error) {
        console.error('Error sending connection request:', error);
        
        // Handle duplicate key error specifically
        if (error.code === 11000) {
            return res.status(400).json({ 
                success: false, 
                message: 'Connection request already sent' 
            });
        }
        
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error' 
        });
    }
});

// Get received connection requests (for notifications)
router.get('/received', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;

        // First, get all pending requests
        const allPendingRequests = await ConnectionRequest.find({
            to: userId,
            status: 'pending'
        })
        .populate('from', 'name profileImage logo email')
        .sort({ createdAt: -1 });

        // Filter out requests from users who are already connected
        const validRequests = [];
        
        for (const request of allPendingRequests) {
            const fromUserId = request.from._id;
            
            // Check if there's an accepted connection between these users
            const existingConnection = await ConnectionRequest.findOne({
                $or: [
                    { from: userId, to: fromUserId, status: 'accepted' },
                    { from: fromUserId, to: userId, status: 'accepted' }
                ]
            });

            // Only include the request if users are not already connected
            if (!existingConnection) {
                validRequests.push(request);
            } else {
                // If users are already connected, mark this pending request as invalid
                // and optionally delete it to clean up the database
                console.log(`Removing invalid request from connected user: ${fromUserId}`);
                await ConnectionRequest.findByIdAndDelete(request._id);
            }
        }

        res.json({
            success: true,
            data: validRequests
        });

    } catch (error) {
        console.error('Error fetching connection requests:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error' 
        });
    }
});

// Accept connection request
router.post('/accept/:requestId', verifyToken, async (req, res) => {
    try {
        const { requestId } = req.params;
        const userId = req.user.userId;

        const request = await ConnectionRequest.findById(requestId)
            .populate('from', 'name profileImage email');

        if (!request) {
            return res.status(404).json({ 
                success: false, 
                message: 'Connection request not found' 
            });
        }

        // Verify the request is for this user
        if (request.to.toString() !== userId) {
            return res.status(403).json({ 
                success: false, 
                message: 'Not authorized' 
            });
        }

        // Check if already accepted (idempotent behavior)
        if (request.status === 'accepted') {
            return res.json({
                success: true,
                message: 'Connection request already accepted',
                data: request
            });
        }

        // Check if already rejected
        if (request.status === 'rejected') {
            return res.status(400).json({
                success: false,
                message: 'Cannot accept a rejected request'
            });
        }

        // Check if users are already connected (additional safety check)
        const existingConnection = await ConnectionRequest.findOne({
            $or: [
                { from: request.from, to: request.to, status: 'accepted' },
                { from: request.to, to: request.from, status: 'accepted' }
            ]
        });

        if (existingConnection) {
            // Delete the invalid pending request
            await ConnectionRequest.findByIdAndDelete(requestId);
            return res.status(400).json({
                success: false,
                message: 'Users are already connected'
            });
        }

        // Update request status
        request.status = 'accepted';
        await request.save();

        res.json({
            success: true,
            message: 'Connection request accepted',
            data: request
        });

    } catch (error) {
        console.error('Error accepting connection request:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error' 
        });
    }
});

// Reject connection request
router.post('/reject/:requestId', verifyToken, async (req, res) => {
    try {
        const { requestId } = req.params;
        const userId = req.user.userId;

        const request = await ConnectionRequest.findById(requestId);

        if (!request) {
            return res.status(404).json({ 
                success: false, 
                message: 'Connection request not found' 
            });
        }

        // Verify the request is for this user
        if (request.to.toString() !== userId) {
            return res.status(403).json({ 
                success: false, 
                message: 'Not authorized' 
            });
        }

        // Check if already rejected (idempotent behavior)
        if (request.status === 'rejected') {
            return res.json({
                success: true,
                message: 'Connection request already rejected'
            });
        }

        // Check if already accepted
        if (request.status === 'accepted') {
            return res.status(400).json({
                success: false,
                message: 'Cannot reject an accepted request'
            });
        }

        // Check if users are already connected (additional safety check)
        const existingConnection = await ConnectionRequest.findOne({
            $or: [
                { from: request.from, to: request.to, status: 'accepted' },
                { from: request.to, to: request.from, status: 'accepted' }
            ]
        });

        if (existingConnection) {
            // Delete the invalid pending request
            await ConnectionRequest.findByIdAndDelete(requestId);
            return res.status(400).json({
                success: false,
                message: 'Users are already connected'
            });
        }

        // Update request status
        request.status = 'rejected';
        await request.save();

        res.json({
            success: true,
            message: 'Connection request rejected'
        });

    } catch (error) {
        console.error('Error rejecting connection request:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error' 
        });
    }
});

// Get sent connection requests
router.get('/sent', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;

        const requests = await ConnectionRequest.find({
            from: userId
        })
        .populate('to', 'name profileImage email')
        .sort({ createdAt: -1 });

        res.json({
            success: true,
            data: requests
        });

    } catch (error) {
        console.error('Error fetching sent requests:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error' 
        });
    }
});

module.exports = router;
