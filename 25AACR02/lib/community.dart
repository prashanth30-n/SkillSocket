import 'package:flutter/material.dart';
import 'package:barter_system/history.dart';
import 'package:barter_system/login.dart';
import 'package:barter_system/profile.dart';
import 'package:barter_system/reviews.dart';
import 'package:barter_system/notification.dart';
import 'package:barter_system/services/post_service.dart';
import 'package:barter_system/models/backend_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

class _CommunityState extends State<Community> {
  final TextEditingController _searchController = TextEditingController();
  List<BackendPost> allPosts = [];
  List<BackendPost> filteredPosts = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  bool hasMorePosts = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPosts();
    _searchController.addListener(() {
      _filterPosts(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('userId');
    });
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentPage = 1;
        hasMorePosts = true;
        isLoading = true;
      });
    }

    try {
      final response = await PostService.getPosts(
        page: currentPage,
        limit: 10,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
      );

      if (response != null) {
        final postsResponse = PostsResponse.fromJson(response);

        setState(() {
          if (refresh || currentPage == 1) {
            allPosts = postsResponse.posts;
          } else {
            allPosts.addAll(postsResponse.posts);
          }
          filteredPosts = allPosts;
          hasMorePosts = postsResponse.pagination.hasNextPage;
          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        // Fallback to dummy data if API fails
        _initializeDummyPosts();
      }
    } catch (e) {
      print('Error loading posts: $e');
      // Fallback to dummy data if API fails
      _initializeDummyPosts();
    }
  }

  void _initializeDummyPosts() {
    // Fallback dummy data structure matching BackendPost
    setState(() {
      allPosts = [
        BackendPost(
          id: '1',
          user: BackendUser(id: '1', name: 'john_dev'),
          content:
              'Just finished learning Java collections! The HashMap implementation is fascinating.',
          image:
              'https://via.placeholder.com/600x400/4CAF50/FFFFFF?text=Java+Code',
          likes: ['user1', 'user2'],
          comments: [
            BackendComment(
              user: BackendUser(id: '2', name: 'sarah_coder'),
              content: 'Great post! HashMap is really powerful.',
              createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
      filteredPosts = allPosts;
      isLoading = false;
    });
  }

  void _filterPosts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPosts = allPosts;
      } else {
        filteredPosts = allPosts.where((post) {
          return post.content.toLowerCase().contains(query.toLowerCase()) ||
              post.user.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    ).then((result) {
      if (result != null && result == true) {
        // Refresh posts when a new post is created
        _loadPosts(refresh: true);
      }
    });
  }

  // Updated to handle BackendPost
  void _openPostViewer(BackendPost post, {bool initialShowComments = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerPage(
          post: post,
          initialShowComments: initialShowComments,
          onUpdate: () {
            // Refresh posts when returning from photo viewer
            _loadPosts(refresh: true);
          },
        ),
      ),
    );
  }

  Future<void> _toggleLike(BackendPost post) async {
    try {
      final result = await PostService.toggleLike(post.id);
      if (result != null) {
        // Update the post in the local list
        setState(() {
          final index = allPosts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            // Create a new post object with updated likes
            final updatedPost = BackendPost(
              id: post.id,
              user: post.user,
              content: post.content,
              image: post.image,
              likes: result['liked']
                  ? [...post.likes, currentUserId!]
                  : post.likes.where((id) => id != currentUserId).toList(),
              comments: post.comments,
              createdAt: post.createdAt,
            );
            allPosts[index] = updatedPost;
            _filterPosts(_searchController.text);
          }
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update like')),
      );
    }
  }

  /*void _navigateToCreateCommunity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCommunityPage(),
      ),
    ).then((newCommunity) {
      if (newCommunity != null && newCommunity is BackendCommunity) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailPage(community: newCommunity),
          ),
        );
      }
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Color(0xFF123b53),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
                child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'SkillSocket',
                      style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 39),
                    ),
                  ),
                ),
              ],
            )),
            ListTile(
              leading: Icon(
                Icons.history,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              title: Text(
                'History',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => History()));
              },
            ),
            Divider(color: Colors.white, thickness: 1),
            ListTile(
              leading: Icon(
                Icons.reviews,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              title: Text(
                'Reviews',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Reviews()));
              },
            ),
            Divider(color: Colors.white, thickness: 1),
            ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                title: Text(
                  'Sign Out',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                }),
            Divider(color: Colors.white, thickness: 1),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'SkillSocket',
          style: TextStyle(
              fontSize: 20,
              //fontStyle: FontStyle.italic,
              color: Color.fromARGB(255, 255, 255, 255)),
        ),
        backgroundColor: Color(0xFF123b53),
        iconTheme:
            IconThemeData(color: const Color.fromARGB(255, 255, 255, 255)),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Notifications()));
              },
              icon: Icon(Icons.notifications)),
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Profile()));
              },
              icon: Icon(Icons.person_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPosts(refresh: true),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Search Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filterPosts,
                decoration: InputDecoration(
                  hintText:
                      'Search posts... (e.g., "java", "flutter", "python")',
                  hintStyle: TextStyle(color: Colors.white),
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Color(0xFF66B7D2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
            // Posts List
            if (filteredPosts.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No posts found',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    Text(
                      'Try searching for "java", "flutter", or "python"',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            else
              ...filteredPosts.map(
                (post) {
                  final isLiked = currentUserId != null &&
                      post.likes.contains(currentUserId);
                  return Container(
                    margin:
                        const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(215, 195, 219, 236),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account details header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF123b53),
                                  shape: BoxShape.circle,
                                ),
                                child: post.user.profileImage != null
                                    ? ClipOval(
                                        child: Image.network(
                                          post.user.profileImage!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.person,
                                                      color: Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.person,
                                        color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.user.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _formatTimestamp(post.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Post content text
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            post.content,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        // Post image (if available)
                        if (post.image != null)
                          GestureDetector(
                            onTap: () => _openPostViewer(post,
                                initialShowComments: false),
                            child: Container(
                              width: double.infinity,
                              height: 200,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  post.image!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.broken_image,
                                            color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        // Action buttons
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(color: Colors.grey[300]!)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Like Button
                              _buildActionButton(
                                isLiked
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                '${post.likes.length}',
                                isLiked
                                    ? const Color(0xFF123b53)
                                    : Colors.grey[700]!,
                                () => _toggleLike(post),
                              ),
                              // Comment Button
                              _buildActionButton(
                                Icons.comment_outlined,
                                '${post.comments.length}',
                                Colors.grey[700]!,
                                () {
                                  _openPostViewer(post,
                                      initialShowComments: true);
                                },
                              ),
                              // Share Button
                              _buildActionButton(
                                Icons.share_outlined,
                                '',
                                Colors.grey[700]!,
                                () {
                                  Share.share(
                                      'Check out this post: ${post.content}\n\n'
                                      '${post.image != null ? 'Image: ${post.image}\n' : ''}'
                                      'Shared from Community App');
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            backgroundColor: const Color(0xFF123b53),
            child: const Icon(Icons.add, color: Colors.white),
            //child: const Icon(Icons.add),
            onPressed: () {
              final RenderBox button = context.findRenderObject() as RenderBox;
              final RenderBox overlay =
                  Overlay.of(context).context.findRenderObject() as RenderBox;
              final Offset buttonTopCenter = button.localToGlobal(
                Offset(button.size.width / 2, 0),
                ancestor: overlay,
              );
              final RelativeRect position = RelativeRect.fromLTRB(
                buttonTopCenter.dx,
                buttonTopCenter.dy - 120,
                overlay.size.width - buttonTopCenter.dx,
                overlay.size.height - buttonTopCenter.dy,
              );
              showMenu(
                context: context,
                position: position,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                items: [
                  PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.post_add, color: Color(0xFF123b53)),
                      title: Text("Create Post"),
                    ),
                    onTap: () {
                      Future.delayed(Duration.zero, () {
                        _navigateToCreatePost();
                      });
                    },
                  ),
                  /* PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.group_add, color: Color(0xFF56195B)),
                      title: Text("Create Community"),
                    ),
                    onTap: () {
                      Future.delayed(Duration.zero, () {
                        _navigateToCreateCommunity();
                      });
                    },
                  ),*/
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: iconColor),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: iconColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class Community extends StatefulWidget {
  const Community({super.key});

  @override
  State<Community> createState() => _CommunityState();
}

class Post {
  final String id;
  final String username;
  final String content;
  final String? imageUrl; // Can be null if no image is selected
  final List<String> tags;
  final DateTime timestamp;
  int likes;
  int shares;
  bool isLiked;
  List<Comment> comments; // This list needs to be mutable

  Post({
    required this.id,
    required this.username,
    required this.content,
    this.imageUrl,
    required this.tags,
    required this.timestamp,
    this.likes = 0,
    this.shares = 0,
    this.isLiked = false,
    required this.comments, // Ensure comments list is passed
  });
}

class Comment {
  final String username;
  final String content;
  final DateTime timestamp;

  Comment({
    required this.username,
    required this.content,
    required this.timestamp,
  });
}

class PhotoViewerPage extends StatefulWidget {
  final BackendPost post;
  final bool initialShowComments;
  final VoidCallback? onUpdate;

  const PhotoViewerPage({
    Key? key,
    required this.post,
    this.initialShowComments = false,
    this.onUpdate,
  }) : super(key: key);

  @override
  _PhotoViewerPageState createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late bool showComments;
  final TextEditingController _commentController = TextEditingController();
  late BackendPost currentPost;

  @override
  void initState() {
    super.initState();
    showComments = widget.initialShowComments;
    currentPost = widget.post;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isNotEmpty) {
      try {
        final response = await PostService.addComment(
          currentPost.id,
          _commentController.text.trim(),
        );

        if (response != null) {
          List<BackendComment> updatedComments = [];
          // Backend returned a list of comments
          updatedComments = response
              .map((c) => BackendComment.fromJson(c as Map<String, dynamic>))
              .toList();
          setState(() {
            currentPost = BackendPost(
              id: currentPost.id,
              user: currentPost.user,
              content: currentPost.content,
              image: currentPost.image,
              likes: currentPost.likes,
              comments: updatedComments,
              createdAt: currentPost.createdAt,
            );
            _commentController.clear();
          });
          widget.onUpdate?.call();
        }
      } catch (e) {
        print('Error adding comment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add comment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Swipe right to close comments, swipe left to open
          if (details.primaryVelocity! > 0) {
            // Swiped right
            if (showComments) {
              // Only change state if comments are currently open
              setState(() {
                showComments = false;
              });
            }
          } else if (details.primaryVelocity! < 0) {
            // Swiped left
            // Only show comments if there are existing comments OR if it's a new comment input.
            // Also, only change state if comments are currently closed.
            if (!showComments) {
              setState(() {
                showComments = true;
              });
            }
          }
        },
        child: Stack(
          children: [
            // Main post content (image or text)
            Column(
              children: [
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            currentPost.user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: currentPost.image != null
                        ? Image.network(
                            currentPost.image!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(Icons.broken_image,
                                      color: Colors.grey, size: 64),
                                ),
                              );
                            },
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              currentPost.content,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                            ),
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Only show text content if an image is present,
                      // otherwise the content is already displayed prominently above.
                      if (currentPost.image != null)
                        Text(
                          currentPost.content,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
            // Comments panel (slides in from right)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut, // Added curve for smoother animation
              right: showComments ? 0 : -MediaQuery.of(context).size.width,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                setState(() {
                                  showComments = false;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Comments',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: currentPost.comments.length,
                        itemBuilder: (context, index) {
                          final comment = currentPost.comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF123b53),
                              child: Text(
                                comment.user.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              comment.user.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment.content),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(comment.createdAt),
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Add Comment Section
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              minLines: 1,
                              maxLines: 4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton(
                            onPressed: _addComment,
                            mini: true,
                            backgroundColor: const Color(0xFF123b53),
                            child: const Icon(Icons.send,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = image;
    });
  }

  void _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter some content for your post')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Creating post..."),
            ],
          ),
        );
      },
    );

    try {
      final result = await PostService.createPost(
        content: _contentController.text.trim(),
        imageFile: _selectedImage != null ? File(_selectedImage!.path) : null,
      );

      // Hide loading indicator
      Navigator.of(context).pop();

      if (result != null) {
        // Post created successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        // Post creation failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to create post. Please try again.')),
        );
      }
    } catch (e) {
      // Hide loading indicator
      Navigator.of(context).pop();

      print('Error creating post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: const Color(0xFF123b53),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _createPost,
            child: const Text(
              'POST',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What\'s on your mind?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText:
                    'Share your thoughts, code snippets, or ask questions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add an image (optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Image selection button
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select Image from Gallery'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF123b53), // Text and icon color
                minimumSize:
                    const Size(double.infinity, 50), // Make button wider
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Image preview
            if (_selectedImage != null)
              Expanded(
                // Use Expanded to give the preview image flexible space
                child: Container(
                  height: 150, // This height will be a maximum, not strict
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImage!.path), // Use File for local image
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Placeholder for CreateCommunityPage

/*class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final tagsController = TextEditingController();

  File? _selectedImage;

  // Add error variables
  String? nameError;
  String? bioError;
  String? tagsError;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

 void _validateAndSubmit() {
    final name = nameController.text.trim();
    final bio = bioController.text.trim();
    final tags = tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    setState(() {
      nameError = name.isEmpty ? 'Please enter a community name.' : null;
      bioError = bio.isEmpty ? 'Please enter a community bio.' : null;
      tagsError = tags.isEmpty ? 'Please enter at least one tag.' : null;
    });

    if (nameError != null || bioError != null || tagsError != null) {
      return;
    }

    final newCommunity = BackendCommunity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      bio: bio,
      tags: tags,
      iconUrl: _selectedImage?.path,
    );

    Navigator.pop(context, newCommunity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Community'),
        backgroundColor: const Color(0xFF56195B),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Label for Icon
                      const Text(
                        'Add Icon of the Community',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Community Icon Picker
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : null,
                          child: _selectedImage == null
                              ? Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey.shade700,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Community Name Field + Error
                      _buildGradientTextField(
                        controller: nameController,
                        hintText: 'Community Name',
                      ),
                      if (nameError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              nameError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Community Bio Field + Error
                      _buildGradientTextField(
                        controller: bioController,
                        hintText: 'Community Bio',
                        maxLines: 6,
                      ),
                      if (bioError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              bioError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Tags Field + Error
                      _buildGradientTextField(
                        controller: tagsController,
                        hintText: 'Tags (comma separated)',
                      ),
                      if (tagsError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              tagsError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Save Button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _validateAndSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF56195B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create Community',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Reusable styled text field widget
  Widget _buildGradientTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECC9EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color.fromARGB(0, 24, 3, 3),
        ),
      ),
    );
  }
}*/
