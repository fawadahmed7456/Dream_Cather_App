import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger_utils.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/social_repository.dart';

// ── States ──────────────────────────────────────────────────────────────────
abstract class SocialState extends Equatable {
  const SocialState();
  @override
  List<Object?> get props => [];
}

class SocialInitial extends SocialState {
  const SocialInitial();
}

class SocialLoading extends SocialState {
  const SocialLoading();
}

class SocialLoaded extends SocialState {
  final List<PostModel> posts;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String? activeCommunity;
  final bool isTrending;

  const SocialLoaded({
    required this.posts,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.activeCommunity,
    this.isTrending = false,
  });

  SocialLoaded copyWith({
    List<PostModel>? posts,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? activeCommunity,
    bool? isTrending,
  }) {
    return SocialLoaded(
      posts: posts ?? this.posts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      activeCommunity: activeCommunity ?? this.activeCommunity,
      isTrending: isTrending ?? this.isTrending,
    );
  }

  @override
  List<Object?> get props => [
        posts,
        hasReachedMax,
        isLoadingMore,
        activeCommunity,
        isTrending,
      ];
}

class SocialError extends SocialState {
  final String message;
  const SocialError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Cubit ───────────────────────────────────────────────────────────────────
class SocialCubit extends Cubit<SocialState> {
  final SocialRepository _repo;
  static const String _tag = 'SocialCubit';
  static const int _pageSize = 10;

  int _currentPage = 0;
  String? _currentCommunity;
  bool _isTrending = false;

  SocialCubit(this._repo) : super(const SocialInitial());

  String? get activeCommunity => _currentCommunity;
  bool get isTrendingMode => _isTrending;

  /// Loads initial posts or reloads feed with optional filter.
  Future<void> loadPosts({
    String? community,
    bool? sortByTrending,
  }) async {
    _currentPage = 0;
    _currentCommunity = community ?? _currentCommunity;
    _isTrending = sortByTrending ?? _isTrending;

    emit(const SocialLoading());

    try {
      final posts = await _repo.fetchPosts(
        page: _currentPage,
        pageSize: _pageSize,
        sortByTrending: _isTrending,
        community: _currentCommunity,
      );

      emit(SocialLoaded(
        posts: posts,
        hasReachedMax: posts.length < _pageSize,
        activeCommunity: _currentCommunity,
        isTrending: _isTrending,
      ));
    } catch (e) {
      Log.e(_tag, 'Failed to load posts: $e');
      emit(SocialError(e.toString()));
    }
  }

  /// Pagination: fetches next page of posts.
  Future<void> loadMorePosts() async {
    final currentState = state;
    if (currentState is! SocialLoaded ||
        currentState.hasReachedMax ||
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = _currentPage + 1;
      final newPosts = await _repo.fetchPosts(
        page: nextPage,
        pageSize: _pageSize,
        sortByTrending: _isTrending,
        community: _currentCommunity,
      );

      _currentPage = nextPage;

      emit(currentState.copyWith(
        posts: [...currentState.posts, ...newPosts],
        hasReachedMax: newPosts.length < _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      Log.e(_tag, 'Failed to load more posts: $e');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// Toggles like on a post with instant optimistic UI update.
  Future<void> toggleLike(String postId) async {
    final currentState = state;
    if (currentState is! SocialLoaded) return;

    final index = currentState.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final targetPost = currentState.posts[index];
    final wasLiked = targetPost.isLikedByMe;
    final newLikeCount = wasLiked
        ? (targetPost.likeCount > 0 ? targetPost.likeCount - 1 : 0)
        : targetPost.likeCount + 1;

    // Optimistic update
    final updatedList = List<PostModel>.from(currentState.posts);
    updatedList[index] = targetPost.copyWith(
      isLikedByMe: !wasLiked,
      likeCount: newLikeCount,
    );
    emit(currentState.copyWith(posts: updatedList));

    try {
      final isNowLiked = await _repo.toggleLike(postId);
      // Reconcile if server state differs
      if (isNowLiked == wasLiked) {
        final revertedList = List<PostModel>.from(currentState.posts);
        revertedList[index] = targetPost;
        emit(currentState.copyWith(posts: revertedList));
      }
    } catch (e) {
      Log.e(_tag, 'Like failed: $e');
      // Revert on failure
      final revertedList = List<PostModel>.from(currentState.posts);
      revertedList[index] = targetPost;
      emit(currentState.copyWith(posts: revertedList));
    }
  }

  /// Increments share count in DB and updates UI.
  Future<void> trackShare(String postId) async {
    final currentState = state;
    if (currentState is! SocialLoaded) return;

    final index = currentState.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final targetPost = currentState.posts[index];
    final updatedList = List<PostModel>.from(currentState.posts);
    updatedList[index] = targetPost.copyWith(shareCount: targetPost.shareCount + 1);
    emit(currentState.copyWith(posts: updatedList));

    try {
      final actualCount = await _repo.trackShare(postId);
      final refreshedList = List<PostModel>.from(currentState.posts);
      refreshedList[index] = targetPost.copyWith(shareCount: actualCount);
      emit(currentState.copyWith(posts: refreshedList));
    } catch (e) {
      Log.e(_tag, 'Share tracking failed: $e');
    }
  }

  /// Creates a new post (text, text+media, media-only).
  Future<PostModel> createPost({
    String? title,
    String? content,
    File? mediaFile,
    String? mediaType,
    String community = 'Friendship',
  }) async {
    String? uploadedUrl;
    if (mediaFile != null) {
      uploadedUrl = await _repo.uploadPostMedia(mediaFile);
    }

    final newPost = await _repo.createPost(
      title: title,
      content: content,
      mediaUrl: uploadedUrl,
      mediaType: mediaType,
      community: community,
    );

    // Prepend to current feed if active
    final currentState = state;
    if (currentState is SocialLoaded) {
      emit(currentState.copyWith(posts: [newPost, ...currentState.posts]));
    }

    return newPost;
  }

  /// Increments local comment count when a comment is added in PostDetailsScreen
  void incrementCommentCount(String postId) {
    final currentState = state;
    if (currentState is! SocialLoaded) return;

    final index = currentState.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final targetPost = currentState.posts[index];
    final updatedList = List<PostModel>.from(currentState.posts);
    updatedList[index] = targetPost.copyWith(commentCount: targetPost.commentCount + 1);
    emit(currentState.copyWith(posts: updatedList));
  }

  /// Deletes the post from Supabase and removes it from the current feed.
  Future<void> deletePost(String postId) async {
    final currentState = state;

    // Optimistically remove from list
    if (currentState is SocialLoaded) {
      final updatedList = currentState.posts.where((p) => p.id != postId).toList();
      emit(currentState.copyWith(posts: updatedList));
    }

    try {
      await _repo.deletePost(postId);
      Log.i(_tag, 'Post $postId deleted');
    } catch (e) {
      Log.e(_tag, 'Delete post failed: $e');
      // Reload feed to restore accurate state
      await loadPosts(community: _currentCommunity);
      rethrow;
    }
  }
}
