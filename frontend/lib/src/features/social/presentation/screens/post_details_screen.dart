import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/size_utils.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/social_repository.dart';
import '../bloc/social_cubit.dart';
import '../widgets/block_confirmation_dialog.dart';
import '../widgets/post_card_widget.dart';
import '../widgets/report_modal_sheet.dart';
import '../widgets/share_sheet_modal.dart';

class PostDetailsScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailsScreen({super.key, required this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late PostModel _post;
  final _commentController = TextEditingController();
  final List<CommentModel> _comments = [];
  bool _isLoadingComments = true;
  bool _isAddingComment = false;
  final int _commentPage = 0;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    final repo = sl<SocialRepository>();
    try {
      final list = await repo.fetchComments(
        postId: _post.id,
        page: _commentPage,
        pageSize: 20,
      );

      if (mounted) {
        setState(() {
          _comments.addAll(list);
          _isLoadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isAddingComment = true);
    final repo = sl<SocialRepository>();

    try {
      final newComment = await repo.addComment(
        postId: _post.id,
        content: content,
      );

      if (!mounted) return;
      _commentController.clear();
      FocusScope.of(context).unfocus();

      setState(() {
        _comments.insert(0, newComment);
        _post = _post.copyWith(commentCount: _post.commentCount + 1);
        _isAddingComment = false;
      });

      // Update parent feed cubit count
      context.read<SocialCubit>().incrementCommentCount(_post.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAddingComment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    }
  }

  void _showMoreMenu() {
    final isMyPost = _post.userId == sl<SocialRepository>().currentUserId;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.adaptSize)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            if (isMyPost) ...[
              // ── Own post: Delete ──
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
                            Navigator.pop(context); // close dialog
                            context.read<SocialCubit>().deletePost(_post.id).then((_) {
                              if (mounted) {
                                Navigator.pop(context); // pop PostDetailsScreen
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
              // ── Other user's post: Report + Block ──
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: Text('Report', style: AppTextStyles.text15Semibold(context)),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ReportModalSheet(postId: _post.id),
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
                      username: _post.authorUsername ?? 'this user',
                      onConfirm: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User blocked')),
                        );
                        Navigator.pop(context);
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

  void _openShareModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareSheetModal(
        postId: _post.id,
        onShareSuccess: () {
          context.read<SocialCubit>().trackShare(_post.id);
          setState(() {
            _post = _post.copyWith(shareCount: _post.shareCount + 1);
          });
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
        title: Text(_post.community, style: AppTextStyles.text18Semibold(context)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Post Card
                  PostCardWidget(
                    post: _post,
                    onLike: () {
                      context.read<SocialCubit>().toggleLike(_post.id);
                      setState(() {
                        final wasLiked = _post.isLikedByMe;
                        _post = _post.copyWith(
                          isLikedByMe: !wasLiked,
                          likeCount: wasLiked ? _post.likeCount - 1 : _post.likeCount + 1,
                        );
                      });
                    },
                    onComment: () {},
                    onShare: _openShareModal,
                    onMoreOptions: _showMoreMenu,
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: Text(
                      'Comments (${_comments.length})',
                      style: AppTextStyles.text16Bold(context),
                    ),
                  ),

                  // Comments List
                  if (_isLoadingComments)
                    const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator(color: AppColors.primary)))
                  else if (_comments.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.adaptSize),
                        child: Text('No comments yet. Be the first to comment!', style: AppTextStyles.helperText(context)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFF0F0F0)),
                      itemBuilder: (context, idx) {
                        final comment = _comments[idx];
                        final initial = (comment.authorUsername?.isNotEmpty == true)
                            ? comment.authorUsername![0].toUpperCase()
                            : 'U';

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16.adaptSize,
                                backgroundColor: AppColors.primary.withOpacity(0.12),
                                backgroundImage: comment.authorAvatarUrl != null
                                    ? CachedNetworkImageProvider(comment.authorAvatarUrl!)
                                    : null,
                                child: comment.authorAvatarUrl == null
                                    ? Text(initial, style: AppTextStyles.text12Semibold(context, textColor: AppColors.primary))
                                    : null,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(comment.authorUsername ?? 'User', style: AppTextStyles.text13Semibold(context)),
                                        SizedBox(width: 8.w),
                                        Text(
                                          timeago.format(comment.createdAt),
                                          style: AppTextStyles.text11Normal(context, textColor: const Color(0xFF9E9E9E)),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      comment.content,
                                      style: AppTextStyles.text14Normal(
                                        context,
                                        textColor: isDark ? AppColors.darkTextPrimary : const Color(0xFF333333),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),

          // Bottom Comment Input Field
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: AppTextStyles.inputText(context),
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: AppTextStyles.inputHint(context),
                        filled: true,
                        fillColor: isDark ? AppColors.darkBgInput : const Color(0xFFF7F8FA),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.adaptSize),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: _isAddingComment
                        ? SizedBox(
                            width: 20.adaptSize,
                            height: 20.adaptSize,
                            child: const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                          )
                        : Icon(Icons.send_rounded, color: AppColors.primary, size: 24.adaptSize),
                    onPressed: _isAddingComment ? null : _submitComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
