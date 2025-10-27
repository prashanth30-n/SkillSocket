const express = require('express');
const http = require('http');
const socketIo=require('socket.io');
const mongoose = require('mongoose');
const PostRoutes = require('./routes/PostRoutes.js');
const authRoutes = require('./routes/authRoutes.js');
const userUpdateRoutes = require('./routes/profileupdate.js');  
const userLogoUploadRoutes = require('./routes/userLogoUpload.js');
const chat = require('./routes/chatRoutes.js'); // AI chatbot route
const messageRoutes = require('./routes/messageRoutes.js'); // Message routes
const skillMatchRoutes = require('./routes/skillMatch.js'); // Skill matching route
const connectionRoutes = require('./routes/connectionRoutes.js'); // Connection requests
const notificationRoutes = require('./routes/notificationRoutes.js'); // Notification routes
const reviewRoutes = require('./routes/reviewRoutes.js'); // Review routes
const todoRoutes = require('./routes/todoRoutes.js'); // Todo routes
const eventRoutes = require('./routes/eventRoutes.js'); // Event routes
const cors = require('cors');

const Message = require('./models/Message.js'); // Import the Message model
const NotificationService = require('./services/notificationService');
const { JsonWebTokenError } = require('jsonwebtoken');
require('dotenv').config();
const app = express();
const server = http.createServer(app);
const io=socketIo(server,{
  cors:{
    methods:['GET', 'POST']
  }
});

app.use(cors());
app.use(express.json());
app.use('/api/posts', PostRoutes);
// Basic health check route
app.get('/', (req, res) => {
  res.status(200).json({ 
    message: 'SkillSocket Backend is running!', 
    status: 'OK',
    timestamp: new Date().toISOString(),
    port: process.env.PORT || 3000
  });
});

// Simple ping endpoint for Render health checks
app.get('/ping', (req, res) => {
  res.status(200).send('pong');
});

// Health check endpoint for Docker and monitoring
app.get('/api/health', (req, res) => {
  const healthCheck = {
    uptime: process.uptime(),
    message: 'OK',
    timestamp: Date.now(),
    status: 'healthy',
    version: process.env.npm_package_version || '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  };
  
  try {
    // Check database connection
    if (mongoose.connection.readyState === 1) {
      healthCheck.database = 'connected';
    } else {
      healthCheck.database = 'disconnected';
      healthCheck.status = 'unhealthy';
    }
    
    res.status(200).json(healthCheck);
  } catch (error) {
    healthCheck.message = error.message;
    healthCheck.status = 'unhealthy';
    res.status(503).json(healthCheck);
  }
});

// Register user update routes
app.use('/api/user', userUpdateRoutes);

// Register user logo upload routes
app.use('/api/user', userLogoUploadRoutes);

// Register auth routes  
app.use('/api/auth', authRoutes);

// Register chatbot routes
app.use('/api/chat', chat);

// Register message routes
app.use('/api/messages', messageRoutes);

// Register skill matching routes
app.use('/api/users', skillMatchRoutes);

// Register connection routes
app.use('/api/connections', connectionRoutes);

// Register notification routes
app.use('/api/notifications', notificationRoutes);

// Register review routes
app.use('/api/reviews', reviewRoutes);

// Register todo routes
app.use('/api/todos', todoRoutes);

// Register event routes
app.use('/api/events', eventRoutes);

// Export io for use in other modules
module.exports = { io };

const MONGODB_URI = process.env.MONGODB_URI;

console.log('📊 Connecting to MongoDB...');
console.log('🔗 MongoDB URI exists:', !!MONGODB_URI);

mongoose.connect(MONGODB_URI, {
  serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
  socketTimeoutMS: 45000, // Close sockets after 45s of inactivity
})
  .then(() => {
    console.log("✅ MongoDB connected successfully");
    console.log("📊 Database ready state:", mongoose.connection.readyState);
  })
  .catch(err => {
    console.error("❌ MongoDB connection error:", err.message);
    process.exit(1);
  });

const onlineUsers = new Map();

io.on('connection', (socket) => {
  console.log('New client connected:', socket.id);
  
  // User joins room
  socket.on('joinRoom', (userId) => {
    onlineUsers.set(userId, socket.id);
    socket.join(userId);
    console.log(`User ${userId} connected with socket ${socket.id}`);
  });

  // Handle typing indicators
  socket.on('typing', ({ from, to }) => {
    if (onlineUsers.has(to)) {
      io.to(to).emit('typing', { from });
    }
  });

  socket.on('stopTyping', ({ from, to }) => {
    if (onlineUsers.has(to)) {
      io.to(to).emit('stopTyping', { from });
    }
  });

  // Handle sending messages
  socket.on('sendMessage', async ({ from, to, content }) => {
    try {
      const newMsg = await Message.create({
        from,
        to,
        content,
        seen: false
      });
      
      // Populate the message with user details
      const populatedMsg = await Message.findById(newMsg._id)
        .populate('from', 'name email')
        .populate('to', 'name email');

      // Send message to recipient
      io.to(to).emit('receiveMessage', populatedMsg);
      
      // Always send push notification for messages (even if user is online)
      // This matches WhatsApp behavior - push notifications for all messages
      await NotificationService.notifyNewMessage(from, to, content, `${from}_${to}`);
      
      // Don't send back to sender to prevent duplicates
      // Instead, emit delivery confirmation
      if (onlineUsers.has(to)) {
        // User is online, message delivered immediately
        io.to(from).emit('messageDelivered', { messageId: newMsg._id });
        
        // After a short delay, mark as read (simulating user seeing the message)
        setTimeout(() => {
          io.to(from).emit('messageRead', { messageId: newMsg._id });
        }, 2000);
      }
    } catch (err) {
      console.error("Error sending message:", err);
    }
  });

  // Handle marking messages as seen
  socket.on('markAsSeen', async ({ from, to }) => {
    try {
      await Message.updateMany(
        { from, to, seen: false },
        { $set: { seen: true } }
      );
      if (onlineUsers.has(from)) {
        io.to(from).emit('messagesSeen', { by: to });
      }
    } catch (err) {
      console.error("Error marking messages as seen:", err);
    }
  });

  // Handle user disconnection
  socket.on('disconnect', () => {
    onlineUsers.forEach((socketId, userId) => {
      if (socketId === socket.id) {
        onlineUsers.delete(userId);
        console.log(`User ${userId} disconnected`);
      }
    });
  });
});

const DEFAULT_PORT = parseInt(process.env.PORT, 10) || 3000;

function startServer(port = DEFAULT_PORT) {
  server.listen(port, '0.0.0.0', () => {
    console.log(`🚀 Server running on port ${port}`);
    console.log(`🌍 Server bound to 0.0.0.0:${port}`);
    console.log(`📋 Public upload endpoint: /api/user/upload-logo-public`);
    console.log(`🔒 Authenticated upload endpoint: /api/user/upload-logo`);
    console.log(`✅ Server ready to accept connections`);
  });

  // Handle server errors (for example, EADDRINUSE)
  server.on('error', (err) => {
    if (err && err.code === 'EADDRINUSE') {
      console.error(`Port ${port} is already in use.`);
      if (port === DEFAULT_PORT) {
        // try next port
        const altPort = port + 1;
        console.log(`Attempting to start on alternate port ${altPort}...`);
        startServer(altPort);
      } else {
        console.error('Alternate port also in use. Exiting.');
        process.exit(1);
      }
    } else {
      console.error('Server error:', err);
      process.exit(1);
    }
  });
}

// Graceful shutdown handlers
process.on('SIGTERM', () => {
  console.log('🔄 SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.log('✅ Server closed');
    mongoose.connection.close(false, () => {
      console.log('✅ MongoDB connection closed');
      process.exit(0);
    });
  });
});

process.on('SIGINT', () => {
  console.log('🔄 SIGINT received, shutting down gracefully...');
  server.close(() => {
    console.log('✅ Server closed');
    mongoose.connection.close(false, () => {
      console.log('✅ MongoDB connection closed');
      process.exit(0);
    });
  });
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('💥 Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Start the server
startServer();