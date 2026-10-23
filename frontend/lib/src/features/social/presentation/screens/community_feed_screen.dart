import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/size_utils.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/social_repository.dart';
import '../bloc/social_cubit.dart';
import '../widgets/block_confirmation_dialog.dart';
import '../widgets/post_card_widget.dart';
import '../widgets/report_modal_sheet.dart';
import '../widgets/share_sheet_modal.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  final String communityName;
  const CommunityFeedScreen({super.key, required this.communityName});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialCubit>().loadPosts(community: widget.communityName);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<SocialCubit>().loadMorePosts();
    }
  }

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<SocialCubit>(),
          child: CreatePostScreen(initialCommunity: widget.communityName),
        ),
      ),
    );
  }

  void _openPostDetails(PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<SocialCubit>(),
          child: PostDetailsScreen(post: post),
        ),
      ),
    );
  }

  void _showMoreMenu(PostModel post) {
    final isMyPost = post.userId == sl<SocialRepository>().currentUserId;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.adaptSize)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            if (isMyPost) ...[
              // ── Own post: show Delete option ──
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text('Delete Post', style: AppTextStyles.text15Semibold(context, textColor: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Post'),
                      content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.read<SocialCubit>().deletePost(post.id).then((_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Post deleted')),
                                );
                              }
                            }).catchError((_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to delete post. Please try again.')),
                                );
                              }
                            });
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              // ── Other user's post: show Report + Block ──
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: Text('Report', style: AppTextStyles.text15Semibold(context)),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ReportModalSheet(postId: post.id),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.redAccent),
                title: Text('Block User', style: AppTextStyles.text15Semibold(context)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => BlockConfirmationDialog(
                      username: post.authorUsername ?? 'this user',
                      onConfirm: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User blocked')),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openShareModal(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareSheetModal(
        postId: post.id,
        onShareSuccess: () {
          context.read<SocialCubit>().trackShare(post.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20.adaptSize),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.communityName, style: AppTextStyles.text18Semibold(context)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              context.watch<SocialCubit>().isTrendingMode
                  ? Icons.local_fire_department
                  : Icons.local_fire_department_outlined,
              color: context.watch<SocialCubit>().isTrendingMode
                  ? Colors.deepOrangeAccent
                  : theme.colorScheme.onSurface,
            ),
            tooltip: 'Trending Feed',
            onPressed: () {
              final isCurrentlyTrending = context.read<SocialCubit>().isTrendingMode;
              context.read<SocialCubit>().loadPosts(
                    community: widget.communityName,
                    sortByTrending: !isCurrentlyTrending,
                  );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Create Post', style: AppTextStyles.primaryButton(context)),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<SocialCubit>().loadPosts(community: widget.communityName),
        child: Column(
          children: [
            // Top "Write something..." prompt box (Matching Friendship screen in Figma)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFEBF6FD),
                borderRadius: BorderRadius.circular(12.adaptSize),
                border: Border.all(color: const Color(0xFFD4ECFC)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 18.adaptSize),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'This community is for posts about ${widget.communityName}',
                      style: AppTextStyles.text12Semibold(context, textColor: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Write something shortcut button
            InkWell(
              onTap: _openCreatePost,
              borderRadius: BorderRadius.circular(12.adaptSize),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12.adaptSize),
                  border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note, color: AppColors.primary, size: 22.adaptSize),
                    SizedBox(width: 10.w),
                    Text(
                      'Write something...',
                      style: AppTextStyles.text14Normal(context, textColor: const Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ),
            ),

            // Posts list
            Expanded(
              child: BlocBuilder<SocialCubit, SocialState>(
                builder: (context, state) {
                  if (state is SocialLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (state is SocialError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, size: 48.adaptSize, color: Colors.grey),
                          SizedBox(height: 12.h),
                          Text('Failed to load posts', style: AppTextStyles.text16Bold(context)),
                          SizedBox(height: 8.h),
                          ElevatedButton(
                            onPressed: () => context.read<SocialCubit>().loadPosts(community: widget.communityName),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is SocialLoaded) {
                    if (state.posts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined, size: 54.adaptSize, color: AppColors.primary.withOpacity(0.5)),
                            SizedBox(height: 12.h),
                            Text('No posts yet in ${widget.communityName}', style: AppTextStyles.text16Bold(context)),
                            SizedBox(height: 6.h),
                            Text('Tap below to start the conversation!', style: AppTextStyles.helperText(context)),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: _openCreatePost,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Create First Post'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, idx) {
                        if (idx == state.posts.length) {
                          return Padding(
                            padding: EdgeInsets.all(16.adaptSize),
                            child: const Center(
                              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                            ),
                          );
                        }

                        final post = state.posts[idx];
                        return PostCardWidget(
                          post: post,
                          onTap: () => _openPostDetails(post),
                          onLike: () => context.read<SocialCubit>().toggleLike(post.id),
                          onComment: () => _openPostDetails(post),
                          onShare: () => _openShareModal(post),
                          onMoreOptions: () => _showMoreMenu(post),
                        );
                      },
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
