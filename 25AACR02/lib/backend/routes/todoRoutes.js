const express = require('express');
const router = express.Router();
const verifyToken = require('../middlewares/verifyToken');
const Todo = require('../models/Todo');

// Helper to normalize a date string (YYYY-MM-DD) to UTC midnight
function normalizeDate(dateStr) {
  // Expecting 'YYYY-MM-DD' from client
  const [y, m, d] = dateStr.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d, 0, 0, 0, 0));
}

// Get todos for a date
// GET /api/todos?date=YYYY-MM-DD
router.get('/', verifyToken, async (req, res) => {
  try {
    const dateStr = req.query.date;
    if (!dateStr) return res.status(400).json({ message: 'date (YYYY-MM-DD) is required' });

    const date = normalizeDate(dateStr);
    const nextDate = new Date(date);
    nextDate.setUTCDate(nextDate.getUTCDate() + 1);

    const todos = await Todo.find({
      user: req.user.userId,
      date: { $gte: date, $lt: nextDate },
    }).sort({ createdAt: 1 });

    res.json(todos);
  } catch (err) {
    console.error('GET /api/todos error', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create todo
// POST /api/todos  { date: 'YYYY-MM-DD', task: string }
router.post('/', verifyToken, async (req, res) => {
  try {
    const { date: dateStr, task } = req.body;
    if (!dateStr || !task) return res.status(400).json({ message: 'date and task are required' });

    const date = normalizeDate(dateStr);
    const todo = await Todo.create({ user: req.user.userId, date, task, done: false });
    res.status(201).json(todo);
  } catch (err) {
    console.error('POST /api/todos error', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update todo (task and/or done)
// PATCH /api/todos/:id  { task?, done? }
router.patch('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { task, done } = req.body;

    const update = {};
    if (typeof task === 'string') update.task = task;
    if (typeof done === 'boolean') update.done = done;

    const updated = await Todo.findOneAndUpdate(
      { _id: id, user: req.user.userId },
      { $set: update },
      { new: true }
    );

    if (!updated) return res.status(404).json({ message: 'Todo not found' });
    res.json(updated);
  } catch (err) {
    console.error('PATCH /api/todos/:id error', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete todo
// DELETE /api/todos/:id
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await Todo.findOneAndDelete({ _id: id, user: req.user.userId });
    if (!deleted) return res.status(404).json({ message: 'Todo not found' });
    res.json({ success: true });
  } catch (err) {
    console.error('DELETE /api/todos/:id error', err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
