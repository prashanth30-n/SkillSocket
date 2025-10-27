const express = require('express');
const router = express.Router();
const upload = require('../middlewares/upload');
const cloudinary = require('../config/cloudinary');
const User = require('../models/User');
const verifyToken = require('../middlewares/verifyToken');

// Upload profile image during signup (no auth required)
router.post('/upload-logo-public', upload.single('logo'), async (req, res) => {
    try {
        console.log('🖼️ Public upload logo called (signup)');

        if (!req.file) {
            return res.status(400).json({ msg: 'No logo file provided' });
        }

        // Upload to Cloudinary
        const result = await new Promise((resolve, reject) => {
            const stream = cloudinary.uploader.upload_stream(
                { folder: 'user-profile-images' },
                (error, result) => {
                    if (error) return reject(error);
                    resolve(result);
                }
            );
            stream.end(req.file.buffer);
        });

        const profileImageUrl = result.secure_url;

        console.log('🖼️ Profile image uploaded successfully (public):', profileImageUrl);
        res.json({ 
            msg: "Profile image uploaded successfully", 
            logoUrl: profileImageUrl
        });

    } catch (err) {
        console.error('Upload profile image error (public):', err);
        res.status(500).json({ msg: "Internal server error", error: err.message });
    }
});

// Upload user profile image (authenticated users only)
router.post('/upload-logo', verifyToken, upload.single('logo'), async (req, res) => {
    try {
        console.log('🖼️ Upload user logo called');
        console.log('🖼️ req.user:', req.user);
        
        // Validate authentication
        if (!req.user || !req.user.userId) {
            console.log('🖼️ Authentication failed - no user or userId');
            return res.status(401).json({ msg: 'Authentication required' });
        }

        if (!req.file) {
            return res.status(400).json({ msg: 'No logo file provided' });
        }

        // Upload to Cloudinary
        const result = await new Promise((resolve, reject) => {
            const stream = cloudinary.uploader.upload_stream(
                { folder: 'user-profile-images' },
                (error, result) => {
                    if (error) return reject(error);
                    resolve(result);
                }
            );
            stream.end(req.file.buffer);
        });

        const profileImageUrl = result.secure_url;

        // Update user with profile image URL
        const updatedUser = await User.findByIdAndUpdate(
            req.user.userId,
            { profileImage: profileImageUrl },
            { new: true }
        ).select('-password');

        if (!updatedUser) {
            return res.status(404).json({ msg: "User not found" });
        }

        console.log('🖼️ Profile image uploaded successfully:', profileImageUrl);
        res.json({ 
            msg: "Profile image uploaded successfully", 
            logoUrl: profileImageUrl,
            user: updatedUser 
        });

    } catch (err) {
        console.error('Upload profile image error:', err);
        res.status(500).json({ msg: "Internal server error" });
    }
});

module.exports = router;
