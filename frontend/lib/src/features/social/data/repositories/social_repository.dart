import 'dart:io';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/logger_utils.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

class SocialRepository {
  final SupabaseClient _supabase;
  static const String _tag = 'SocialRepository';

  SocialRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Maps raw Supabase [StorageException] messages to user-friendly strings.
  String _mapStorageError(StorageException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('bucket not found') || msg.contains('no such bucket')) {
      return 'Media storage is not configured yet. Please contact support.';
    }
    if (msg.contains('payload too large') || msg.contains('file size')) {
      return 'File is too large. Maximum allowed size is 50 MB.';
    }
    if (msg.contains('mime') || msg.contains('content-type') || msg.contains('invalid mime')) {
      return 'Unsupported file type. Please upload a JPEG, PNG, or MP4 file.';
    }
    if (msg.contains('not authorized') || msg.contains('forbidden') || msg.contains('permission')) {
      return 'You do not have permission to upload media. Please re-login and try again.';
    }
    return 'Media upload failed: ${e.message}';
  }

  /// Uploads media file to Supabase Storage [AppConfig.postMediaBucket] bucket.
  /// Throws a user-friendly [Exception] on failure.
  Future<String> uploadPostMedia(File file) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final ext = file.path.split('.').last.toLowerCase();
    final fileBytes = await file.readAsBytes();
    final fileName = '$userId/${const Uuid().v4()}.$ext';
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    Log.i(_tag, 'Uploading media: $fileName ($mimeType), size=${fileBytes.lengthInBytes} bytes');

    try {
      await _supabase.storage.from(AppConfig.postMediaBucket).uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );
    } on StorageException catch (e) {
      Log.e(_tag, 'Storage upload error: ${e.message} | statusCode=${e.statusCode}');
      throw Exception(_mapStorageError(e));
    } catch (e) {
      Log.e(_tag, 'Unexpected upload error: $e');
      throw Exception('An unexpected error occurred while uploading media. Please try again.');
    }

    final publicUrl =
        _supabase.storage.from(AppConfig.postMediaBucket).getPublicUrl(fileName);

    Log.i(_tag, 'Media uploaded successfully: $publicUrl');
    return publicUrl;
  }

  /// Creates a new post (text only, text+media, media only).
  Future<PostModel> createPost({
    String? title,
    String? content,
    String? mediaUrl,
    String? mediaType,
    String community = 'Friendship',
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final postData = {
      'user_id': userId,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (content != null && content.trim().isNotEmpty) 'content': content.trim(),
      if (mediaUrl != null && mediaUrl.trim().isNotEmpty) 'media_url': mediaUrl.trim(),
      if (mediaType != null) 'media_type': mediaType,
      'community': community,
    };

    Log.i(_tag, 'Creating post for user $userId in $community');

    final res = await _supabase
        .from('posts')
        .insert(postData)
        .select('*, users(username, avatar_url)')
        .single();

    return PostModel.fromJson(res, currentUserId: userId);
  }

  /// Fetches paginated posts (efficiently a few posts at a time).
  /// [sortByTrending]: if true, orders by trending_score DESC; else created_at DESC.
  /// [community]: optional filter by community name (e.g., 'Friendship').
  Future<List<PostModel>> fetchPosts({
    int page = 0,
    int pageSize = 10,
    bool sortByTrending = false,
    String? community,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final userId = currentUserId;

    Log.i(_tag, 'Fetching posts: page=$page, size=$pageSize, trending=$sortByTrending, community=$community');

    PostgrestFilterBuilder<PostgrestList> filter = _supabase
        .from('posts')
        .select('*, users(username, avatar_url)');

    if (community != null && community.isNotEmpty && community.toLowerCase() != 'all') {
      filter = filter.eq('community', community);
    }

    PostgrestTransformBuilder<PostgrestList> ordered;
    if (sortByTrending) {
      ordered = filter
          .order('trending_score', ascending: false)
          .order('created_at', ascending: false);
    } else {
      ordered = filter.order('created_at', ascending: false);
    }

    final List<dynamic> response = await ordered.range(from, to);

    // Fetch user's likes for these posts in a single efficient query
    List<String> myLikedPostIds = [];
    if (userId != null && response.isNotEmpty) {
      final postIds = response.map((p) => p['id'] as String).toList();
      final likesRes = await _supabase
          .from('likes')
          .select('post_id')
          .eq('user_id', userId)
          .filter('post_id', 'in', postIds);

      myLikedPostIds = (likesRes as List<dynamic>)
          .map((row) => row['post_id'] as String)
          .toList();
    }

    return response
        .map((json) => PostModel.fromJson(
              json as Map<String, dynamic>,
              currentUserId: userId,
              myLikedPostIds: myLikedPostIds,
            ))
        .toList();
  }

  /// Toggles like on a post. Returns true if now liked, false if unliked.
  Future<bool> toggleLike(String postId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final existing = await _supabase
        .from('likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // Unlike
      await _supabase
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      Log.i(_tag, 'Unliked post $postId');
      return false;
    } else {
      // Like
      await _supabase.from('likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
      Log.i(_tag, 'Liked post $postId');
      return true;
    }
  }

  /// Tracks a share count in the database (as requested in scope).
  Future<int> trackShare(String postId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    Log.i(_tag, 'Tracking share for post $postId');

    await _supabase.from('shares').insert({
      'post_id': postId,
      'user_id': userId,
    });

    final updated = await _supabase
        .from('posts')
        .select('share_count')
        .eq('id', postId)
        .single();

    return (updated['share_count'] as num?)?.toInt() ?? 0;
  }

  /// Adds a comment to a post.
  Future<CommentModel> addComment({
    required String postId,
    required String content,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    Log.i(_tag, 'Adding comment on post $postId');

    final res = await _supabase
        .from('comments')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'content': content.trim(),
        })
        .select('*, users(username, avatar_url)')
        .single();

    return CommentModel.fromJson(res);
  }

  /// Fetches comments for a post efficiently (paginated).
  Future<List<CommentModel>> fetchComments({
    required String postId,
    int page = 0,
    int pageSize = 20,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final List<dynamic> response = await _supabase
        .from('comments')
        .select('*, users(username, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .range(from, to);

    return response
        .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a post owned by the current user.
  /// Supabase RLS ensures only the post owner can delete it.
  Future<void> deletePost(String postId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    Log.i(_tag, 'Deleting post $postId');

    await _supabase
        .from('posts')
        .delete()
        .eq('id', postId)
        .eq('user_id', userId);

    Log.i(_tag, 'Post $postId deleted successfully');
  }
}
