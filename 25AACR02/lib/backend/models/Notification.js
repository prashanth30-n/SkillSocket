const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    recipient: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    sender: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: false // System notifications won't have a sender
    },
    type: {
        type: String,
        enum: [
            'message',           // New chat message
            'connection_request', // Someone wants to connect
            'connection_accepted', // Connection request accepted
            'skill_match',       // New skill match found
            'post_like',         // Someone liked your post
            'post_comment',      // Someone commented on your post
            'system'             // System notifications
        ],
        required: true
    },
    title: {
        type: String,
        required: true
    },
    body: {
        type: String,
        required: true
    },
    data: {
        type: mongoose.Schema.Types.Mixed, // Additional data (chatId, postId, etc.)
        default: {}
    },
    read: {
        type: Boolean,
        default: false
    },
    delivered: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Index for efficient queries
notificationSchema.index({ recipient: 1, createdAt: -1 });
notificationSchema.index({ recipient: 1, read: 1 });

module.exports = mongoose.models.Notification || mongoose.model('Notification', notificationSchema);
