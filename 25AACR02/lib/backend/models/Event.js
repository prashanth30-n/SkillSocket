const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    date: { type: Date, required: true, index: true }, // store date at 00:00 UTC
    title: { type: String, required: true, trim: true },
  },
  { timestamps: true }
);

// Index for efficient querying by user and date
eventSchema.index({ user: 1, date: 1 });

module.exports = mongoose.model('Event', eventSchema);