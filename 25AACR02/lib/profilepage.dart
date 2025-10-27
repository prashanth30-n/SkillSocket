import 'package:flutter/material.dart';
import 'package:barter_system/services/user_service.dart';
import 'package:barter_system/services/review_service.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String name;

  const UserProfilePage({super.key, required this.userId, required this.name});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _reviews = [];
  String? _loggedInUserName;

  @override
  void initState() {
    super.initState();
    _fetchLoggedInUserName();
    _loadUserProfile();
  }

  Future<void> _fetchLoggedInUserName() async {
    final user = await UserService.getUserProfile();
    setState(() {
      _loggedInUserName = user?['name']?.toString();
    });
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final userProfile = await UserService.getUserProfileById(widget.userId);
      final reviewsData =
          await ReviewService.getUserReviews(userId: widget.userId);
      final reviews = reviewsData?['reviews'] ?? [];

      setState(() {
        _userProfile = userProfile;
        _reviews = List<Map<String, dynamic>>.from(reviews).map((review) {
          return {
            'reviewer': review['reviewer']?['name']?.toString() ?? 'Anonymous',
            'title': review['title']?.toString() ?? '',
            'comment': review['comment']?.toString() ?? '',
            'rating': review['rating'] ?? 0,
            'date': _formatDate(review['createdAt']?.toString()),
            'id': review['_id']?.toString() ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print("Error loading user profile: $e");
    }

    setState(() => _isLoading = false);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildInfoCard(IconData icon, String label, String? value) {
    return Card(
      color: const Color(0xFFB6E1F0),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF123b53)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(
                    value ?? "Not provided",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF123b53),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog() {
    final TextEditingController reviewController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    double selectedRating = 5.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text(
                "Write a Review",
                style: TextStyle(
                    color: Color(0xFF123b53), fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loggedInUserName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFF123b53)),
                            const SizedBox(width: 8),
                            Text(
                              _loggedInUserName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF123b53),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Rating:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF123b53),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedRating = (index + 1).toDouble();
                                  });
                                },
                                child: Icon(
                                  Icons.star,
                                  size: 32,
                                  color: index < selectedRating
                                      ? Colors.amber
                                      : Colors.grey[300],
                                ),
                              );
                            }),
                          ),
                          Center(
                            child: Text(
                              "${selectedRating.toInt()}/5 Stars",
                              style: const TextStyle(
                                color: Color(0xFF123b53),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        controller: titleController,
                        maxLines: 1,
                        decoration: InputDecoration(
                          hintText: "Review title (e.g., 'Great teaching!')",
                          filled: true,
                          fillColor: const Color(0xFFB6E1F0).withOpacity(0.3),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Share your experience...",
                        filled: true,
                        fillColor: const Color(0xFFB6E1F0).withOpacity(0.3),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF123b53)),
                  onPressed: () async {
                    final review = reviewController.text.trim();
                    final title = titleController.text.trim();

                    if (review.isNotEmpty && title.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Submitting review..."),
                        duration: Duration(seconds: 1),
                      ));

                      final result = await UserService.addReview(
                        userId: widget.userId,
                        rating: selectedRating,
                        title: title,
                        comment: review,
                      );

                      Navigator.pop(context);

                      if (result != null && result['success'] == true) {
                        final newReview = {
                          'reviewer': _loggedInUserName ?? 'You',
                          'title': title,
                          'comment': review,
                          'rating': selectedRating.toInt(),
                          'date': _formatDate(DateTime.now().toIso8601String()),
                          'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
                        };

                        setState(() {
                          _reviews.insert(0, newReview);
                        });

                        _loadUserProfile();

                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Review submitted successfully!"),
                                backgroundColor: Colors.green));
                      } else {
                        final errorMsg =
                            result?['message'] ?? 'Failed to submit review';
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Error: $errorMsg"),
                            backgroundColor: Colors.red));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Please fill in both title and review"),
                          backgroundColor: Colors.orange));
                    }
                  },
                  child: const Text("Submit",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF123b53),
        icon: const Icon(Icons.rate_review, color: Colors.white),
        label:
            const Text("Write Review", style: TextStyle(color: Colors.white)),
        onPressed: _showReviewDialog,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF123b53)),
            )
          : _userProfile == null
              ? const Center(child: Text("Profile not found"))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 250,
                      pinned: true,
                      backgroundColor: const Color(0xFF123b53),
                      iconTheme: const IconThemeData(color: Colors.white),
                      title: const Text(""),
                      flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCollapsed =
                              constraints.maxHeight <= kToolbarHeight + 40;
                          return FlexibleSpaceBar(
                            title: isCollapsed
                                ? Text(widget.name,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 18))
                                : null,
                            centerTitle: true,
                            background: Container(
                              color: const Color(0xFF123b53),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: const Color(0xFFB6E1F0),
                                    backgroundImage:
                                        (_userProfile?['profileImage']
                                                    is String &&
                                                (_userProfile?['profileImage']
                                                        as String)
                                                    .isNotEmpty)
                                            ? NetworkImage(
                                                _userProfile!['profileImage'])
                                            : null,
                                    child: _userProfile?['profileImage'] == null
                                        ? const Icon(Icons.person,
                                            size: 70, color: Colors.white70)
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _userProfile?['name']?.toString() ?? "",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _userProfile?['profession']?.toString() ??
                                        "Not provided",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 16),
                        _buildInfoCard(Icons.person, "Name",
                            _userProfile?['name']?.toString()),
                        _buildInfoCard(Icons.school, "Education",
                            _userProfile?['education']?.toString()),
                        _buildInfoCard(Icons.work, "Profession",
                            _userProfile?['profession']?.toString()),
                        _buildInfoCard(
                            Icons.business_center,
                            "Currently Working",
                            _userProfile?['currentlyWorking']?.toString()),
                        _buildInfoCard(
                            Icons.lightbulb,
                            "Skills Required",
                            (_userProfile?['skillsRequired'] is List)
                                ? (_userProfile!['skillsRequired'] as List)
                                    .join(", ")
                                : null),
                        _buildInfoCard(
                            Icons.handshake,
                            "Skills Offered",
                            (_userProfile?['skillsOffered'] is List)
                                ? (_userProfile!['skillsOffered'] as List)
                                    .join(", ")
                                : null),
                        _buildInfoCard(
                          Icons.cake,
                          "Date of Birth",
                          _userProfile?['dateOfBirth'] != null
                              ? (() {
                                  try {
                                    final date = DateTime.parse(
                                        _userProfile!['dateOfBirth']);
                                    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                                  } catch (e) {
                                    return _userProfile!['dateOfBirth']
                                        .toString();
                                  }
                                })()
                              : null,
                        ),
                        _buildInfoCard(Icons.location_on, "Location",
                            _userProfile?['location']?.toString()),
                        _buildInfoCard(
                            Icons.star,
                            "Skills",
                            (_userProfile?['skills'] is List)
                                ? (_userProfile!['skills'] as List).join(", ")
                                : null),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Reviews",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF123b53),
                                          ),
                                        ),
                                        if (_reviews.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF123b53),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "${_reviews.length} review${_reviews.length == 1 ? '' : 's'}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                              if (_reviews.isEmpty)
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 20.0),
                                  child: Text(
                                    "No reviews yet. Be the first to write one!",
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.grey),
                                  ),
                                ),
                              if (_reviews.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Column(
                                    children: [
                                      ..._reviews.map((review) => Card(
                                            color: const Color(0xFFB6E1F0),
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        review['reviewer']
                                                                ?.toString() ??
                                                            "Anonymous",
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xFF123b53),
                                                        ),
                                                      ),
                                                      Row(
                                                        children: List.generate(
                                                            5, (index) {
                                                          final rating = review[
                                                                  'rating'] ??
                                                              0;
                                                          return Icon(
                                                            index < rating
                                                                ? Icons.star
                                                                : Icons
                                                                    .star_border,
                                                            size: 16,
                                                            color: Colors.amber,
                                                          );
                                                        }),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  if (review['title']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true)
                                                    Text(
                                                      review['title']
                                                              ?.toString() ??
                                                          "",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xFF123b53),
                                                      ),
                                                    ),
                                                  if (review['title']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true)
                                                    const SizedBox(height: 4),
                                                  Text(
                                                    review['comment']
                                                            ?.toString() ??
                                                        review['review']
                                                            ?.toString() ??
                                                        "",
                                                    style: const TextStyle(
                                                        fontSize: 15),
                                                  ),
                                                  if (review['date'] != null)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 8.0),
                                                      child: Text(
                                                        review['date']
                                                            .toString(),
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ))
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ],
                ),
    );
  }
}
