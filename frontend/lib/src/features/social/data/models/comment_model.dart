import 'package:equatable/equatable.dart';

class CommentModel extends Equatable {
  final String id;
  final String userId;
  final String postId;
  final String content;
  final DateTime createdAt;

  // Joined author metadata
  final String? authorUsername;
  final String? authorAvatarUrl;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.content,
    required this.createdAt,
    this.authorUsername,
    this.authorAvatarUrl,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    final userMap = json['users'] is Map<String, dynamic>
        ? json['users'] as Map<String, dynamic>
        : null;

    return CommentModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: parseDate(json['created_at']),
      authorUsername: userMap?['username'] as String? ?? json['author_username'] as String?,
      authorAvatarUrl: userMap?['avatar_url'] as String? ?? json['author_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'post_id': postId,
      'content': content.trim(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        postId,
        content,
        createdAt,
        authorUsername,
        authorAvatarUrl,
      ];
}
