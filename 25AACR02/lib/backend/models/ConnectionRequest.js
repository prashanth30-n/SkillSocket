const mongoose = require('mongoose');

const connectionRequestSchema = new mongoose.Schema({
    from: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    to: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'accepted', 'rejected'],
        default: 'pending'
    },
    message: {
        type: String,
        default: ''
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

// Index for efficient querying (removed unique constraint to allow resending after rejection)
connectionRequestSchema.index({ from: 1, to: 1 });
connectionRequestSchema.index({ from: 1, to: 1, status: 1 });

// Update the updatedAt field before saving
connectionRequestSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

module.exports = mongoose.model('ConnectionRequest', connectionRequestSchema);
