const mongoose = require('mongoose');

const todoSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    date: { type: Date, required: true, index: true }, // store date at 00:00 UTC
    task: { type: String, required: true, trim: true },
    done: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// Ensure per-user per-day duplicate prevention optional index (task uniqueness per day)
// Uncomment if you want unique tasks per day for a user
// todoSchema.index({ user: 1, date: 1, task: 1 }, { unique: true });

module.exports = mongoose.model('Todo', todoSchema);
