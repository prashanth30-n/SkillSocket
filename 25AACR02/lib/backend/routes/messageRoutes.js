const express=require('express');
const router=express.Router();
const Message=require('../models/Message.js'); // Import the Message model
const User=require('../models/User.js'); // Import the User model - fixed capitalization
const verifyToken=require('../middlewares/verifyToken.js'); // Middleware to verify JWT  

// Get conversations for the user
router.get('/conversations', verifyToken, async (req, res) => {
    try {
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
        res.json({ conversations });
    } catch (e) {
        console.error("❌ Error fetching conversations:", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

router.get('/:otherUserId',verifyToken,async(req,res)=>{
    try{
        const{otherUserId}=req.params;
        const userId=req.user.userId;
        
    const messages = await Message.find({
      $or: [
        { from: userId, to: otherUserId },
        { from: otherUserId, to: userId }
      ]
    })
    .populate('from', 'name email profileImage')
    .populate('to', 'name email profileImage')
    .sort({ createdAt: 1 });
    
    res.json({ messages });
    }
    catch(e)
{ console.error("❌ Error fetching messages:", e );
    res.status(500).json({ error: "Internal server error" });

}});

// Search users for new conversations
router.get('/search/users', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        const searchQuery = req.query.q;

        if (!searchQuery || searchQuery.trim().length < 2) {
            return res.status(400).json({ error: 'Search query must be at least 2 characters' });
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

        res.json({ users });
    } catch (e) {
        console.error("❌ Error searching users:", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

router.get('/unread/count', verifyToken, async (req, res) => {
    try{
        const userId=req.user.userId;
        const unreadCounts = await Message.aggregate([
      { $match: { to: userId, seen: false } },
      { $group: { _id: "$from", count: { $sum: 1 } } }
    ]);

    res.json(unreadCounts); 
    }
    catch(e){
        console.error("❌ Error fetching unread count:", e  );
    res.status(500).json({ error: "Internal server error" });
    }
});
router.post('/mark-seen/:otherUserId', verifyToken, async (req, res) => {
    try {
        const { otherUserId } = req.params;
        const userId = req.user.userId;

        await Message.updateMany(
            { from: otherUserId, to: userId, seen: false },
            { $set: { seen: true } }
        );

        res.status(200).json({ message: "Messages marked as seen" });
    } catch (e) {
        console.error("❌ Error marking messages as seen:", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

module.exports = router;