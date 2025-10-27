const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Review = require('../models/Review');
const User = require('../models/User'); // Fixed capitalization
const verifyToken = require('../middlewares/verifyToken');

// Like a review
router.post('/like/:reviewId', verifyToken, async (req, res) => {
    try {
        const { reviewId } = req.params;
        const userId = req.user.userId;
        const review = await Review.findById(reviewId);
        if (!review) return res.status(404).json({ success: false, message: 'Review not found' });

        // Compare by string to handle ObjectId vs string
        if (review.likes.some(id => id.toString() === userId)) {
            review.likes = review.likes.filter(id => id.toString() !== userId); // undo like
        } else {
            review.likes.push(userId); // add like
            review.dislikes = review.dislikes.filter(id => id.toString() !== userId); // remove dislike if exists
        }

        await review.save();

        res.json({
            success: true,
            likes: review.likes.length,
            dislikes: review.dislikes.length
        });
    } catch (e) {
        console.error('Error liking review:', e);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// Dislike a review
router.post('/dislike/:reviewId', verifyToken, async (req, res) => {
    try {
        const { reviewId } = req.params;
        const userId = req.user.userId;
        const review = await Review.findById(reviewId);
        if (!review) return res.status(404).json({ success: false, message: 'Review not found' });

        // Compare by string to handle ObjectId vs string
        if (review.dislikes.some(id => id.toString() === userId)) {
            review.dislikes = review.dislikes.filter(id => id.toString() !== userId); // undo dislike
        } else {
            review.dislikes.push(userId); // add dislike
            review.likes = review.likes.filter(id => id.toString() !== userId); // remove like if exists
        }

        await review.save();

        res.json({
            success: true,
            likes: review.likes.length,
            dislikes: review.dislikes.length
        });
    } catch (e) {
        console.error('Error disliking review:', e);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// Add a review
router.post('/add', verifyToken, async (req, res) => {
    try {
        const reviewerId = req.user.userId;
        const { revieweeId, rating, title, comment } = req.body;

        // Validate required fields
        if (!revieweeId || !rating || !title || !comment) {
            return res.status(400).json({
                success: false,
                message: 'revieweeId, rating, title, and comment are required'
            });
        }

        // Validate rating range
        if (rating < 1 || rating > 5) {
            return res.status(400).json({
                success: false,
                message: 'Rating must be between 1 and 5'
            });
        }

        // Don't allow self-reviews
        if (reviewerId === revieweeId) {
            return res.status(400).json({
                success: false,
                message: 'Cannot review yourself'
            });
        }

        // Check if reviewee exists
        const reviewee = await User.findById(revieweeId);
        if (!reviewee) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        // Check if review already exists
        const existingReview = await Review.findOne({
            reviewer: reviewerId,
            reviewee: revieweeId
        });

        if (existingReview) {
            return res.status(400).json({
                success: false,
                message: 'You have already reviewed this user'
            });
        }

        // Create new review
        const review = new Review({
            reviewer: reviewerId,
            reviewee: revieweeId,
            rating,
            title,
            comment  // ✅ Fixed: Added missing comment field
        });

        await review.save();

        // Populate the review with reviewer details
        const populatedReview = await Review.findById(review._id)
            .populate('reviewer', 'name profileImage logo email')
            .populate('reviewee', 'name');

        res.status(201).json({
            success: true,
            message: 'Review added successfully',
            data: populatedReview
        });

    } catch (error) {
        console.error('Error adding review:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

// Get reviews for a user
router.get('/user/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const { page = 1, limit = 10 } = req.query;

        const skip = (page - 1) * limit;

        // Get reviews for the user
        const reviews = await Review.find({ reviewee: userId })
            .populate('reviewer', 'name profileImage logo email')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(parseInt(limit));

        // Calculate average rating
        const ratingStats = await Review.aggregate([
            { $match: { reviewee: new mongoose.Types.ObjectId(userId) } },
            {
                $group: {
                    _id: null,
                    averageRating: { $avg: '$rating' },
                    totalReviews: { $sum: 1 },
                    ratingDistribution: {
                        $push: '$rating'
                    }
                }
            }
        ]);

        const stats = ratingStats.length > 0 ? ratingStats[0] : {
            averageRating: 0,
            totalReviews: 0,
            ratingDistribution: []
        };

        // Calculate rating distribution
        const distribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
        stats.ratingDistribution.forEach(rating => {
            distribution[rating] = (distribution[rating] || 0) + 1;
        });

        res.json({
            success: true,
            data: {
                reviews,
                stats: {
                    averageRating: Math.round(stats.averageRating * 10) / 10, // Round to 1 decimal
                    totalReviews: stats.totalReviews,
                    distribution
                },
                hasMore: reviews.length === parseInt(limit)
            }
        });

    } catch (error) {
        console.error('Error fetching reviews:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

// Get reviews written by a user
router.get('/by-user/:userId', verifyToken, async (req, res) => {
    try {
        const { userId } = req.params;
        const requestingUserId = req.user.userId;

        // Only allow users to see their own written reviews
        if (userId !== requestingUserId) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized'
            });
        }

        const reviews = await Review.find({ reviewer: userId })
            .populate('reviewee', 'name profileImage logo email')
            .sort({ createdAt: -1 });

        res.json({
            success: true,
            data: reviews
        });

    } catch (error) {
        console.error('Error fetching user reviews:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

// Update a review
router.put('/update/:reviewId', verifyToken, async (req, res) => {
    try {
        const { reviewId } = req.params;
        const reviewerId = req.user.userId;
        const { rating, title, comment } = req.body;

        const review = await Review.findById(reviewId);

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found'
            });
        }

        // Only allow the reviewer to update their own review
        if (review.reviewer.toString() !== reviewerId) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this review'
            });
        }

        // Update fields if provided
        if (rating !== undefined) {
            if (rating < 1 || rating > 5) {
                return res.status(400).json({
                    success: false,
                    message: 'Rating must be between 1 and 5'
                });
            }
            review.rating = rating;
        }
        if (title !== undefined) review.title = title;
        if (comment !== undefined) review.comment = comment;

        await review.save();

        const populatedReview = await Review.findById(review._id)
            .populate('reviewer', 'name profileImage logo email')
            .populate('reviewee', 'name');

        res.json({
            success: true,
            message: 'Review updated successfully',
            data: populatedReview
        });

    } catch (error) {
        console.error('Error updating review:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

// Delete a review
router.delete('/delete/:reviewId', verifyToken, async (req, res) => {
    try {
        const { reviewId } = req.params;
        const reviewerId = req.user.userId;

        const review = await Review.findById(reviewId);

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found'
            });
        }

        // Only allow the reviewer to delete their own review
        if (review.reviewer.toString() !== reviewerId) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete this review'
            });
        }

        await Review.findByIdAndDelete(reviewId);

        res.json({
            success: true,
            message: 'Review deleted successfully'
        });

    } catch (error) {
        console.error('Error deleting review:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

module.exports = router;
