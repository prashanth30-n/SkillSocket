class BackendPost {
  final String id;
  final BackendUser user;
  final String content;
  final String? image;
  final List<String> likes;
  final List<BackendComment> comments;
  final DateTime createdAt;

  BackendPost({
    required this.id,
    required this.user,
    required this.content,
    this.image,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  factory BackendPost.fromJson(Map<String, dynamic> json) {
    return BackendPost(
      id: json['_id'] ?? '',
      user: BackendUser.fromJson(json['user'] ?? {}),
      content: json['content'] ?? '',
      image: json['image'],
      likes: List<String>.from(json['likes'] ?? []),
      comments: (json['comments'] as List?)
              ?.map((comment) => BackendComment.fromJson(comment))
              .toList() ??
          [],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user.toJson(),
      'content': content,
      'image': image,
      'likes': likes,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class BackendUser {
  final String id;
  final String name;
  final String? profileImage;

  BackendUser({
    required this.id,
    required this.name,
    this.profileImage,
  });

  factory BackendUser.fromJson(Map<String, dynamic> json) {
    return BackendUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown User',
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'profileImage': profileImage,
    };
  }
}

class BackendComment {
  final BackendUser user;
  final String content;
  final DateTime createdAt;

  BackendComment({
    required this.user,
    required this.content,
    required this.createdAt,
  });

  factory BackendComment.fromJson(Map<String, dynamic> json) {
    return BackendComment(
      user: BackendUser.fromJson(json['user'] ?? {}),
      content: json['text'] ??
          json['content'] ??
          '', // Handle both 'text' and 'content' fields
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PostsResponse {
  final List<BackendPost> posts;
  final Pagination pagination;

  PostsResponse({
    required this.posts,
    required this.pagination,
  });

  factory PostsResponse.fromJson(Map<String, dynamic> json) {
    return PostsResponse(
      posts: (json['posts'] as List?)
              ?.map((post) => BackendPost.fromJson(post))
              .toList() ??
          [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int totalPosts;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPrevPage;

  Pagination({
    required this.totalPosts,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalPosts: json['totalPosts'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }
}
