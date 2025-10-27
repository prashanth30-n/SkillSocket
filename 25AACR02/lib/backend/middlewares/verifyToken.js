const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  try {
    console.log('🔐 VerifyToken middleware called');
    console.log('🔐 Request headers:', req.headers);
    
    // Get token from header
    const authHeader = req.headers.authorization;
    console.log('🔐 Auth header:', authHeader);
    
    if (!authHeader) {
      console.log('🔐 No auth header found');
      return res.status(401).json({ message: 'Access denied. No token provided.' });
    }

    // Extract token from "Bearer TOKEN"
    const token = authHeader.split(' ')[1];
    console.log('🔐 Extracted token:', token ? 'Token exists' : 'No token');
    
    if (!token) {
      console.log('🔐 Invalid token format');
      return res.status(401).json({ message: 'Access denied. Invalid token format.' });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret_key');
    console.log('🔐 Decoded token:', decoded);
    
    // Add user info to request object - FIX: Use req.user structure
    req.user = {
      userId: decoded.userId,
      email: decoded.email
    };
    
    console.log('🔐 Set req.user to:', req.user);
    
    next();
  } catch (error) {
    console.log('🔐 Token verification error:', error);
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token expired. Please log in again.' });
    } else if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ message: 'Invalid token. Please log in again.' });
    } else {
      console.error('Token verification error:', error);
      return res.status(500).json({ message: 'Server error during token verification.' });
    }
  }
};

module.exports = verifyToken;
