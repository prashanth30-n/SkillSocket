// routes/posts.js
const express = require('express');                        // 1: express import
const router = express.Router();                           // 2: create a router
const upload = require('../middlewares/upload');           // 3: multer memory-storage middleware (you made this)
const cloudinary = require('../config/cloudinary');       // 4: your cloudinary config (you made this)
const Post = require('../models/Post');                    // 5: Post mongoose model
const verifyToken = require('../middlewares/verifyToken'); // 6: auth middleware that sets req.user.userId

const MAX_LIMIT = 50; // 7: maximum items per page to prevent huge responses

// ---------------------------- CREATE POST ----------------------------
router.post('/', verifyToken, upload.single('image'), async (req, res) => {
  try {
    console.log('📝 Create post called');
    console.log('📝 req.user:', req.user);
    
    // Validate authentication
    if (!req.user || !req.user.userId) {
      console.log('📝 Authentication failed - no user or userId');
      return res.status(401).json({ msg: 'Authentication required' });
    }

    const { content } = req.body;                          // 12: text content from client
    console.log('📝 Content:', content);
    console.log('📝 File:', req.file ? 'File uploaded' : 'No file');
    
    // 13: if neither text nor image provided -> bad request
    if (!content && !req.file) return res.status(400).json({ msg: 'Post must contain text or an image' });

    let imageUrl = null;                                   // 16: default when no image uploaded

    // 17: if a file was uploaded, stream it to Cloudinary
    if (req.file) {
      const result = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: 'posts' },                            // 20: optional folder in your Cloudinary account
          (error, result) => {
            if (error) return reject(error);              // 22: reject promise on error
            resolve(result);                              // 23: resolve with Cloudinary result
          }
        );
        stream.end(req.file.buffer);                      // 26: send the file buffer to Cloudinary
      });

      imageUrl = result.secure_url;                       // 28: take the secure CDN URL returned
    }

    // 31: create & save the post (only store the image URL)
    const newPost = new Post({
      user: req.user.userId,
      content,
      image: imageUrl
    });
    
    console.log('📝 New post object:', newPost);

    await newPost.save();                                 // 37: persist to MongoDB
    console.log('📝 Post saved successfully');

    // 38: fetch the saved post populated with user fields to return a nicer payload
    const populated = await Post.findById(newPost._id)
      .populate('user', 'name profileImage')
      .lean();

    console.log('📝 Populated post:', populated);
    return res.status(201).json(populated);               // 43: return created post
  } catch (err) {
    console.error('Create post error:', err);             // 45: log for debugging
    return res.status(500).json({ msg: 'Internal server error' });
  }
});

// ---------------------------- GET POSTS (paginated + filters) ----------------------------
router.get('/', verifyToken, async (req, res) => {
  try {
    console.log('📋 Get posts called');
    console.log('📋 req.user:', req.user);
    
    // Validate authentication
    if (!req.user || !req.user.userId) {
      console.log('📋 Authentication failed - no user or userId');
      return res.status(401).json({ msg: 'Authentication required' });
    }

    const page = Math.max(1, parseInt(req.query.page) || 1);                 // 55: ensure page >=1
    const limit = Math.min(MAX_LIMIT, parseInt(req.query.limit) || 10);      // 56: ensure limit <= MAX_LIMIT
    const skip = (page - 1) * limit;                                        // 57: number to skip

    // 59: build filter object (optional filters supported)
    const filter = {};
    if (req.query.user) filter.user = req.query.user;                       // 60: filter by a single user
    if (req.query.search) filter.content = { $regex: req.query.search, $options: 'i' }; // 61: text search in content

    // 64: run countDocuments & find in parallel for performance
    const [totalPosts, posts] = await Promise.all([
      Post.countDocuments(filter),
      Post.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('user', 'name profileImage')                              // 70: show user name+image only
        .populate('comments.user', 'name profileImage')                     // 71: populate comment authors
        .lean()
    ]);

    const totalPages = Math.max(1, Math.ceil(totalPosts / limit));         // 75: compute pages
    const pagination = {
      totalPosts,
      totalPages,
      currentPage: page,
      pageSize: limit,
      hasNextPage: page < totalPages,
      hasPrevPage: page > 1
    };

    console.log('📋 Returning posts:', posts.length);
    return res.json({ posts, pagination });                                // 84: return feed + meta
  } catch (err) {
    console.error('Get posts error:', err);
    return res.status(500).json({ msg: 'Internal server error' });
  }
});

// ---------------------------- GET SINGLE POST ----------------------------
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const p = await Post.findById(req.params.id)
      .populate('user', 'name profileImage')
      .populate('comments.user', 'name profileImage')
      .lean();

    if (!p) return res.status(404).json({ msg: 'Post not found' });        // 100: not found
    return res.json(p);                                                     // 101: send post
  } catch (err) {
    console.error('Get post by id error:', err);
    return res.status(500).json({ msg: 'Internal server error' });
  }
});

// ---------------------------- TOGGLE LIKE ----------------------------
router.post('/:id/like', verifyToken, async (req, res) => {
  try {
    console.log('❤️ Toggle like called');
    console.log('❤️ req.user:', req.user);
    
    // Validate authentication
    if (!req.user || !req.user.userId) {
      console.log('❤️ Authentication failed - no user or userId');
      return res.status(401).json({ msg: 'Authentication required' });
    }

    const p = await Post.findById(req.params.id);                          // 111: find post
    if (!p) return res.status(404).json({ msg: 'Post not found' });

    const userId = req.user.userId;

    // 116: if liked already, remove (unlike), otherwise add (like)
    if (p.likes.includes(userId)) {
      p.likes.pull(userId);
      await p.save();
      console.log('❤️ Post unliked');
      return res.json({ likes: p.likes.length, liked: false });
    } else {
      p.likes.push(userId);
      await p.save();
      console.log('❤️ Post liked');
      return res.json({ likes: p.likes.length, liked: true });
    }
  } catch (err) {
    console.error('Like error:', err);
    return res.status(500).json({ msg: 'Internal server error' });
  }
});

// ---------------------------- ADD COMMENT ----------------------------
router.post('/:id/comment', verifyToken, async (req, res) => {
  try {
    console.log('💬 Add comment called');
    console.log('💬 req.user:', req.user);
    console.log('💬 req.body:', req.body);
    
    // Validate authentication
    if (!req.user || !req.user.userId) {
      console.log('💬 Authentication failed - no user or userId');
      return res.status(401).json({ msg: 'Authentication required' });
    }

    const { text } = req.body; // Changed from 'content' to 'text' to match frontend
    if (!text) return res.status(400).json({ msg: 'Comment text required' });

    const p = await Post.findById(req.params.id);
    if (!p) return res.status(404).json({ msg: 'Post not found' });

    const comment = { user: req.user.userId, text: text, createdAt: new Date() };
    p.comments.push(comment);
    await p.save();

    console.log('💬 Comment added successfully');

    // return populated comments so frontend can display user info immediately
    const populated = await Post.findById(p._id).populate('comments.user', 'name profileImage').select('comments').lean();
    return res.json(populated.comments);
  } catch (err) {
    console.error('Comment error:', err);
    return res.status(500).json({ msg: 'Internal server error' });
  }
});

// ---------------------------- DELETE POST (owner only) ----------------------------
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const p = await Post.findById(req.params.id);
    if (!p) return res.status(404).json({ msg: 'Post not found' });

    // only owner can delete
    if (p.user.toString() !== req.user.userId) return res.status(403).json({ msg: 'Not authorized' });

    await Post.findByIdAndDelete(req.params.id);
    return res.json({ msg: 'Post deleted' });
  } catch (err) {
    console.error('Delete error:', err);
    return res.status(500).json({ msg: 'Internal server error' });
  }
});

module.exports = router; // 157: export the router
