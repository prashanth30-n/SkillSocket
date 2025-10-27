const express = require('express');
const verifyToken = require('../middlewares/verifyToken');
const router = express.Router();
require('dotenv').config();

// Try to import and initialize Gemini AI with fallback
let model = null;
let aiAvailable = false;

try {
  const { GoogleGenerativeAI } = require('@google/generative-ai');
  
  if (process.env.GEMINI_API_KEY) {
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    aiAvailable = true;
  }
} catch (error) {
  aiAvailable = false;
}

// Predefined responses for common study-related questions
const studyResponses = {
  greeting: [
    "Hello! I'm your study assistant. How can I help you with your learning today?",
    "Hi there! What subject or topic would you like to explore?",
    "Welcome! I'm here to help with your studies. What can I assist you with?"
  ],
  general: [
    "I'm here to help with your studies! What specific topic would you like to learn about?",
    "Great question! For better assistance, could you provide more details about what you're trying to learn?",
    "I'd be happy to help you with that! Can you tell me more about your learning goals?",
    "That's an interesting topic! What specific aspect would you like me to explain?",
    "I'm here to support your learning journey! What would you like to explore today?"
  ],
  math: [
    "Mathematics is a fascinating subject! Are you working on algebra, calculus, geometry, or another area?",
    "I can help with math problems! What specific concept or problem are you working on?",
    "Math can be challenging but rewarding. What mathematical topic do you need help with?"
  ],
  science: [
    "Science is amazing! Are you studying biology, chemistry, physics, or another science?",
    "I love helping with science topics! What specific area or concept interests you?",
    "Science questions are great! What scientific concept would you like to explore?"
  ],
  programming: [
    "Programming is an excellent skill! What language or concept are you working with?",
    "Coding questions are welcome! Are you learning a specific programming language?",
    "I can help with programming! What coding challenge are you facing?"
  ]
};

// Function to get intelligent fallback response
function getIntelligentResponse(message) {
  const lowerMessage = message.toLowerCase();
  
  // Greeting detection
  if (lowerMessage.includes('hello') || lowerMessage.includes('hi') || lowerMessage.includes('hey')) {
    return studyResponses.greeting[Math.floor(Math.random() * studyResponses.greeting.length)];
  }
  
  // Subject-specific responses
  if (lowerMessage.includes('math') || lowerMessage.includes('algebra') || lowerMessage.includes('calculus') || lowerMessage.includes('geometry')) {
    return studyResponses.math[Math.floor(Math.random() * studyResponses.math.length)];
  }
  
  if (lowerMessage.includes('science') || lowerMessage.includes('biology') || lowerMessage.includes('chemistry') || lowerMessage.includes('physics')) {
    return studyResponses.science[Math.floor(Math.random() * studyResponses.science.length)];
  }
  
  if (lowerMessage.includes('programming') || lowerMessage.includes('code') || lowerMessage.includes('javascript') || lowerMessage.includes('python')) {
    return studyResponses.programming[Math.floor(Math.random() * studyResponses.programming.length)];
  }
  
  // Default response
  return studyResponses.general[Math.floor(Math.random() * studyResponses.general.length)];
}

// Chat endpoint for AI responses
router.post('/', async (req, res) => {
  try {
    const { message } = req.body;
    
    if (!message || message.trim() === '') {
      return res.status(400).json({ 
        success: false, 
        error: 'Message is required' 
      });
    }

    let reply;
    let usingFallback = false;

    // Try AI first if available
    if (aiAvailable && model) {
      try {
        const prompt = `You are a helpful study assistant and skill exchange mentor. You help students and professionals with learning, skill development, and academic questions. Keep your responses concise but informative.

User question: ${message}

Please provide a helpful response:`;

        const result = await model.generateContent(prompt);
        const response = await result.response;
        reply = response.text();
      } catch (aiError) {
        reply = getIntelligentResponse(message);
        usingFallback = true;
      }
    } else {
      // Use intelligent fallback
      reply = getIntelligentResponse(message);
      usingFallback = true;
    }

    res.json({
      success: true,
      reply: reply,
      fallback: usingFallback,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    // Always provide a helpful response even on error
    const fallbackResponse = getIntelligentResponse(req.body.message || "hello");
    
    res.json({
      success: true,
      reply: fallbackResponse,
      fallback: true,
      timestamp: new Date().toISOString()
    });
  }
});

// Health check for chat service


module.exports = router;
