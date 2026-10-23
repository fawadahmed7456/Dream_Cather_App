import 'package:equatable/equatable.dart';

class PostModel extends Equatable {
  final String id;
  final String userId;
  final String? title;
  final String? content;
  final String? mediaUrl;
  final String? mediaType; // 'image' | 'video'
  final String community;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final double trendingScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined author metadata
  final String? authorUsername;
  final String? authorAvatarUrl;

  // Client-state
  final bool isLikedByMe;

  const PostModel({
    required this.id,
    required this.userId,
    this.title,
    this.content,
    this.mediaUrl,
    this.mediaType,
    this.community = 'Friendship',
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.trendingScore = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.authorUsername,
    this.authorAvatarUrl,
    this.isLikedByMe = false,
  });

  bool get hasMedia => mediaUrl != null && mediaUrl!.trim().isNotEmpty;
  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image' || (hasMedia && !isVideo);

  factory PostModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    List<String>? myLikedPostIds,
  }) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    final postId = json['id'] as String? ?? '';
    final userMap = json['users'] is Map<String, dynamic>
        ? json['users'] as Map<String, dynamic>
        : null;

    final isLiked = myLikedPostIds != null
        ? myLikedPostIds.contains(postId)
        : (json['is_liked'] as bool? ?? false);

    return PostModel(
      id: postId,
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String?,
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] as String?,
      community: json['community'] as String? ?? 'Friendship',
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
      trendingScore: (json['trending_score'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      authorUsername: userMap?['username'] as String? ?? json['author_username'] as String?,
      authorAvatarUrl: userMap?['avatar_url'] as String? ?? json['author_avatar_url'] as String?,
      isLikedByMe: isLiked,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      if (title != null && title!.trim().isNotEmpty) 'title': title!.trim(),
      if (content != null && content!.trim().isNotEmpty) 'content': content!.trim(),
      if (mediaUrl != null && mediaUrl!.trim().isNotEmpty) 'media_url': mediaUrl!.trim(),
      if (mediaType != null) 'media_type': mediaType,
      'community': community,
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? mediaUrl,
    String? mediaType,
    String? community,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    double? trendingScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorUsername,
    String? authorAvatarUrl,
    bool? isLikedByMe,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      community: community ?? this.community,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      trendingScore: trendingScore ?? this.trendingScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        content,
        mediaUrl,
        mediaType,
        community,
        likeCount,
        commentCount,
        shareCount,
        trendingScore,
        createdAt,
        updatedAt,
        authorUsername,
        authorAvatarUrl,
        isLikedByMe,
      ];
}
