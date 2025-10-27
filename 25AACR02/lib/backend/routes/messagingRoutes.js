const express = require('express');
const router = express.Router();
const Message = require('../models/Message');
const User = require('../models/User');
const verifyToken = require('../middlewares/verifyToken');

// Get user conversations
router.get('/conversations', verifyToken, async (req, res) => {
  try {
    console.log('💬 Get conversations called');
    console.log('💬 req.user:', req.user);
    
    // Validate authentication
    if (!req.user || !req.user.userId) {
      console.log('💬 Authentication failed - no user or userId');
      return res.status(401).json({ msg: 'Authentication required' });
    }

    const userId = req.user.userId;

    // Find all messages where user is either sender or receiver
    const messages = await Message.find({
      $or: [{ from: userId }, { to: userId }]
    })
    .populate('from', 'name email profileImage')
    .populate('to', 'name email profileImage')
    .sort({ createdAt: -1 });

    // Group messages by conversation partner
    const conversationsMap = new Map();
    
    for (const message of messages) {
      const partnerId = message.from._id.toString() === userId ? 
        message.to._id.toString() : message.from._id.toString();
      
      if (!conversationsMap.has(partnerId)) {
        const partner = message.from._id.toString() === userId ? message.to : message.from;
        conversationsMap.set(partnerId, {
          _id: `${userId}_${partnerId}`,
          participant: {
            _id: partner._id,
            name: partner.name,
            email: partner.email,
            profileImage: partner.profileImage
          },
          lastMessage: {
            content: message.content,
            createdAt: message.createdAt,
            from: message.from._id,
            seen: message.seen
          }
        });
      }
    }

    const conversations = Array.from(conversationsMap.values());
    console.log('💬 Found conversations:', conversations.length);

    res.json({ conversations });
  } catch (err) {
    console.error('Get conversations error:', err);
    res.status(500).json({ msg: 'Internal server error' });
  }
});

// Get messages for a specific conversation
router.get('/messages/:partnerId', verifyToken, async (req, res) => {
  try {
    console.log('💬 Get messages called');
    console.log('💬 req.user:', req.user);
    console.log('💬 partnerId:', req.params.partnerId);
    
    // Validate authentication
    if (!req.user || !req.user.userId) {
      console.log('💬 Authentication failed - no user or userId');
      return res.status(401).json({ msg: 'Authentication required' });
    }

    const userId = req.user.userId;
    const partnerId = req.params.partnerId;

    // Find messages between the two users
    const messages = await Message.find({
      $or: [
        { from: userId, to: partnerId },
        { from: partnerId, to: userId }
      ]
    })
    .populate('from', 'name email profileImage')
    .populate('to', 'name email profileImage')
    .sort({ createdAt: 1 }); // Oldest first for chat display

    console.log('💬 Found messages:', messages.length);

    res.json({ messages });
  } catch (err) {
    console.error('Get messages error:', err);
    res.status(500).json({ msg: 'Internal server error' });
  }
});

// Create or get existing conversation
router.post('/conversation', verifyToken, async (req, res) => {
  try {
    console.log('💬 Create conversation called');
    console.log('💬 req.user:', req.user);
    console.log('💬 req.body:', req.body);
    
    // Validate authentication
    if (!req.user || !req.user.userId) {
      console.log('💬 Authentication failed - no user or userId');
      return res.status(401).json({ msg: 'Authentication required' });
    }

    const userId = req.user.userId;
    const { recipientId } = req.body;

    if (!recipientId) {
      return res.status(400).json({ msg: 'Recipient ID required' });
    }

    // Check if recipient exists
    const recipient = await User.findById(recipientId).select('name email profileImage');
    if (!recipient) {
      return res.status(404).json({ msg: 'Recipient not found' });
    }

    // Return conversation info (no need to create anything in DB for this simple approach)
    const conversation = {
      _id: `${userId}_${recipientId}`,
      participant: {
        _id: recipient._id,
        name: recipient.name,
        email: recipient.email,
        profileImage: recipient.profileImage
      }
    };

    console.log('💬 Conversation created/retrieved:', conversation);
    res.status(201).json({ conversation });
  } catch (err) {
    console.error('Create conversation error:', err);
    res.status(500).json({ msg: 'Internal server error' });
  }
});

// Mark messages as read
router.post('/mark-read/:partnerId', verifyToken, async (req, res) => {
  try {
    console.log('💬 Mark as read called');
    
    // Validate authentication
    if (!req.user || !req.user.userId) {
      return res.status(401).json({ msg: 'Authentication required' });
    }

    const userId = req.user.userId;
    const partnerId = req.params.partnerId;

    // Mark all messages from partner to user as seen
    await Message.updateMany(
      { from: partnerId, to: userId, seen: false },
      { $set: { seen: true } }
    );

    console.log('💬 Messages marked as read');
    res.json({ msg: 'Messages marked as read' });
  } catch (err) {
    console.error('Mark as read error:', err);
    res.status(500).json({ msg: 'Internal server error' });
  }
});

// Search users for new conversations
router.get('/search-users', verifyToken, async (req, res) => {
  try {
    console.log('💬 Search users called');
    console.log('💬 req.user:', req.user);
    console.log('💬 query:', req.query.q);
    
    // Validate authentication
    if (!req.user || !req.user.userId) {
      console.log('💬 Authentication failed - no user or userId');
      return res.status(401).json({ msg: 'Authentication required' });
    }

    const userId = req.user.userId;
    const searchQuery = req.query.q;

    if (!searchQuery || searchQuery.trim().length < 2) {
      return res.status(400).json({ msg: 'Search query must be at least 2 characters' });
    }

    // Search for users by name or email (excluding current user)
    const users = await User.find({
      _id: { $ne: userId }, // Exclude current user
      $or: [
        { name: { $regex: searchQuery, $options: 'i' } },
        { email: { $regex: searchQuery, $options: 'i' } }
      ]
    })
    .select('name email profileImage')
    .limit(20); // Limit results

    console.log('💬 Found users:', users.length);
    res.json({ users });
  } catch (err) {
    console.error('Search users error:', err);
    res.status(500).json({ msg: 'Internal server error' });
  }
});

// Get online users (placeholder - would integrate with socket.io)
router.get('/online-users', verifyToken, async (req, res) => {
  try {
    // This would normally get online users from socket.io
    // For now, return empty array
    res.json({ onlineUsers: [] });
  } catch (err) {
    console.error('Get online users error:', err);
    res.status(500).json({ msg: 'Internal server error' });
  }
});

module.exports = router;
