const express = require('express');
const router = express.Router();
const verifyToken = require('../middlewares/verifyToken');
const Event = require('../models/Event');

// Helper to normalize a date string (YYYY-MM-DD) to UTC midnight
function normalizeDate(dateStr) {
  // Expecting 'YYYY-MM-DD' from client
  const [y, m, d] = dateStr.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d, 0, 0, 0, 0));
}

// Get events for a date
// GET /api/events?date=YYYY-MM-DD
router.get('/', verifyToken, async (req, res) => {
  try {
    const dateStr = req.query.date;
    if (!dateStr) return res.status(400).json({ message: 'date (YYYY-MM-DD) is required' });

    const date = normalizeDate(dateStr);
    const nextDate = new Date(date);
    nextDate.setUTCDate(nextDate.getUTCDate() + 1);

    const events = await Event.find({
      user: req.user.userId,
      date: { $gte: date, $lt: nextDate },
    }).sort({ createdAt: 1 });

    res.json(events);
  } catch (err) {
    console.error('GET /api/events error', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create event
// POST /api/events  { date: 'YYYY-MM-DD', title: string }
router.post('/', verifyToken, async (req, res) => {
  try {
    const { date: dateStr, title } = req.body;
    if (!dateStr || !title) return res.status(400).json({ message: 'date and title are required' });

    const date = normalizeDate(dateStr);
    const event = await Event.create({ user: req.user.userId, date, title });
    res.status(201).json(event);
  } catch (err) {
    console.error('POST /api/events error', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update event (title)
// PATCH /api/events/:id  { title }
router.patch('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { title } = req.body;

    if (typeof title !== 'string' || !title.trim()) {
      return res.status(400).json({ message: 'title is required' });
    }

    const updated = await Event.findOneAndUpdate(
      { _id: id, user: req.user.userId },
      { $set: { title: title.trim() } },
      { new: true }
    );

    if (!updated) return res.status(404).json({ message: 'Event not found' });
    res.json(updated);
  } catch (err) {
    console.error('PATCH /api/events/:id error', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete event
// DELETE /api/events/:id
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await Event.findOneAndDelete({ _id: id, user: req.user.userId });
    if (!deleted) return res.status(404).json({ message: 'Event not found' });
    res.json({ success: true });
  } catch (err) {
    console.error('DELETE /api/events/:id error', err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;