import 'package:flutter/material.dart';
import 'package:barter_system/services/review_service.dart';
import 'package:barter_system/services/user_service.dart';

class Reviews extends StatefulWidget {
  const Reviews({super.key});

  @override
  State<Reviews> createState() => _ReviewsState();
}

class _ReviewsState extends State<Reviews> {
  List<Map<String, dynamic>> _givenReviews = [];
  List<Map<String, dynamic>> _receivedReviews = [];
  bool _loadingGiven = true;
  bool _loadingReceived = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final userId = await UserService.getCurrentUserId();

    final given = await ReviewService.getMyReviews();
      setState(() {
      _givenReviews = (given ?? []).map<Map<String, dynamic>>((r) {
        final name = r['reviewee']?['name']?.toString() ?? 'Unknown';
        final created = r['createdAt']?.toString();

        final likesCount = (r['likes'] is num) ? r['likes'] : (r['likes'] is List ? (r['likes'] as List).length : 0);
        final dislikesCount = (r['dislikes'] is num) ? r['dislikes'] : (r['dislikes'] is List ? (r['dislikes'] as List).length : 0);
        final isLiked = userId != null && (r['likes'] is List ? (r['likes'] as List).any((id) => id.toString() == userId) : false);
        final isDisliked = userId != null && (r['dislikes'] is List ? (r['dislikes'] as List).any((id) => id.toString() == userId) : false);

        final mapped = _mapToUi(
          user: name,
          dateIso: created,
          title: r['title']?.toString() ?? '',
          body: r['comment']?.toString() ?? '',
          rating: (r['rating'] is num) ? (r['rating'] as num).round() : 0,
          id: r['_id']?.toString() ?? '',
        );

        mapped['likes'] = likesCount.toString();
        mapped['dislikes'] = dislikesCount.toString();
        mapped['isLiked'] = isLiked;
        mapped['isDisliked'] = isDisliked;

        return mapped;
      }).toList();
      _loadingGiven = false;
    });

    if (userId != null) {
      final receivedData = await ReviewService.getUserReviews(userId: userId);
      final reviews =
          List<Map<String, dynamic>>.from(receivedData?['reviews'] ?? []);
      setState(() {
        _receivedReviews = reviews.map<Map<String, dynamic>>((r) {
          final name = r['reviewer']?['name']?.toString() ?? 'Unknown';
          final created = r['createdAt']?.toString();
          final likesCount = (r['likes'] is num) ? r['likes'] : (r['likes'] is List ? (r['likes'] as List).length : 0);
          final dislikesCount = (r['dislikes'] is num) ? r['dislikes'] : (r['dislikes'] is List ? (r['dislikes'] as List).length : 0);
          final isLiked = (r['likes'] is List ? (r['likes'] as List).any((id) => id.toString() == userId) : false);
          final isDisliked = (r['dislikes'] is List ? (r['dislikes'] as List).any((id) => id.toString() == userId) : false);

          final mapped = _mapToUi(
            user: name,
            dateIso: created,
            title: r['title']?.toString() ?? '',
            body: r['comment']?.toString() ?? '',
            rating: (r['rating'] is num) ? (r['rating'] as num).round() : 0,
            id: r['_id']?.toString() ?? '',
          );

          // Override default like/dislike fields
          mapped['likes'] = likesCount.toString();
          mapped['dislikes'] = dislikesCount.toString();
          mapped['isLiked'] = isLiked;
          mapped['isDisliked'] = isDisliked;

          return mapped;
        }).toList();
        _loadingReceived = false;
      });
    } else {
      setState(() {
        _receivedReviews = [];
        _loadingReceived = false;
      });
    }
  }

  Map<String, dynamic> _mapToUi({
    required String user,
    String? dateIso,
    required String title,
    required String body,
    required int rating,
    required String id,
  }) {
    return {
      'user': user,
      'date': _relativeTime(dateIso),
      'title': title,
      'body': body,
      'likes': '0',
      'dislikes': '0',
      'color': const Color.fromARGB(255, 150, 198, 229),
      'rating': rating.clamp(0, 5),
      'id': id,
      'isLiked': false,
      'isDisliked': false,
    };
  }

  String _relativeTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays >= 7) {
        return 'on ${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } else if (diff.inDays >= 1) {
        return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
      } else if (diff.inHours >= 1) {
        return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
      } else if (diff.inMinutes >= 1) {
        return '${diff.inMinutes} min ago';
      } else {
        return 'just now';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Reviews',
            style: TextStyle(fontSize: 30, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF123b53),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Given Reviews"),
              Tab(text: "Received Reviews"),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        body: TabBarView(
          children: [
            _loadingGiven
                ? const Center(child: CircularProgressIndicator())
                : _givenReviews.isEmpty
                    ? const Center(child: Text('No given reviews yet'))
                    : _buildReviewList(_givenReviews),
            _loadingReceived
                ? const Center(child: CircularProgressIndicator())
                : _receivedReviews.isEmpty
                    ? const Center(child: Text('No received reviews yet'))
                    : _buildReviewList(_receivedReviews),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewList(List<Map<String, dynamic>> reviews) {
    return ListView.builder(
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final post = reviews[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: post['color'],
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(184, 4, 2, 2),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + User + Stars + Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.person,
                                size: 16, color: Colors.black),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              post['user'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < post['rating']
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 14,
                                color: Colors.yellow[700],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      post['date'],
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  post['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post['body'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // Bottom row: only likes and dislikes
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Like button
                    _iconButton(Icons.thumb_up_alt_outlined, post, 'likes',
                        'isLiked', 'isDisliked'),
                    const SizedBox(width: 16),
                    // Dislike button
                    _iconButton(Icons.thumb_down_alt_outlined, post, 'dislikes',
                        'isDisliked', 'isLiked'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper function to make icon+text clickable
Widget _iconButton(
  IconData icon,
  Map<String, dynamic> post,
  String countField,
  String toggleField,
  String otherToggleField,
) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () async {
        // Call API
        Map<String, dynamic>? data;
        if (toggleField == 'isLiked') {
          data = await ReviewService.likeReview(post['id']);
        } else {
          data = await ReviewService.dislikeReview(post['id']);
        }

        if (data != null && data['success'] == true) {
          setState(() {
            // Update counts from backend
            post['likes'] = data?['likes'].toString();
            post['dislikes'] = data?['dislikes'].toString();

            // Update toggles
            if (toggleField == 'isLiked') {
              post['isLiked'] = !post['isLiked'];
              if (post['isDisliked'] == true) post['isDisliked'] = false;
            } else {
              post['isDisliked'] = !post['isDisliked'];
              if (post['isLiked'] == true) post['isLiked'] = false;
            }
          });
        } else {
          // Optional: show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update like/dislike')),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: _iconText(
          icon,
          post[countField],
          color: post[toggleField] ? Colors.blue : Colors.black,
        ),
      ),
    ),
  );
}

  // Icon + text widget
  Widget _iconText(IconData icon, String text, {Color? color}) {
    final c = color ?? Colors.black;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: c)),
      ],
    );
  }
}
