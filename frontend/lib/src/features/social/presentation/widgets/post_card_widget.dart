import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/utils/size_utils.dart';
import '../../data/models/post_model.dart';
import 'post_video_player.dart';

class PostCardWidget extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onTap;
  final VoidCallback? onMoreOptions;

  const PostCardWidget({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onTap,
    this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final initial = (post.authorUsername?.isNotEmpty == true)
        ? post.authorUsername![0].toUpperCase()
        : 'U';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.adaptSize),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(16.adaptSize),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16.adaptSize),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFEFEFEF),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Avatar, Name, Time, Menu ──
            Row(
              children: [
                CircleAvatar(
                  radius: 20.adaptSize,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage: post.authorAvatarUrl != null
                      ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                      : null,
                  child: post.authorAvatarUrl == null
                      ? Text(
                          initial,
                          style: AppTextStyles.text16Bold(
                            context,
                            textColor: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorUsername ?? 'Anonymous',
                        style: AppTextStyles.text15Semibold(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        timeago.format(post.createdAt),
                        style: AppTextStyles.text11Normal(
                          context,
                          textColor: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    color: const Color(0xFF9E9E9E),
                    size: 20.adaptSize,
                  ),
                  onPressed: onMoreOptions,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),

            // ── Title (Optional) ──
            if (post.title != null && post.title!.trim().isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                post.title!,
                style: AppTextStyles.text16Bold(context),
              ),
            ],

            // ── Content Text ──
            if (post.content != null && post.content!.trim().isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                post.content!,
                style: AppTextStyles.text14Normal(
                  context,
                  textColor: isDark
                      ? AppColors.darkTextPrimary
                      : const Color(0xFF4A4A4A),
                ).copyWith(height: 1.45),
              ),
            ],

            // ── Media Attachment (Image or Video) ──
            if (post.hasMedia) ...[
              SizedBox(height: 12.h),
              if (post.isVideo)
                PostVideoPlayerWidget(videoUrl: post.mediaUrl!)
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.adaptSize),
                  child: CachedNetworkImage(
                    imageUrl: post.mediaUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200.h,
                      color: isDark ? AppColors.darkBgInput : const Color(0xFFF2F4F7),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150.h,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
            ],

            SizedBox(height: 14.h),

            // ── Bottom Interaction Row: Likes, Comments, Shares ──
            Row(
              children: [
                // Like Button
                InkWell(
                  onTap: onLike,
                  borderRadius: BorderRadius.circular(8.adaptSize),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                    child: Row(
                      children: [
                        Icon(
                          post.isLikedByMe
                              ? FontAwesomeIcons.solidThumbsUp
                              : FontAwesomeIcons.thumbsUp,
                          size: 15.adaptSize,
                          color: post.isLikedByMe
                              ? AppColors.primary
                              : const Color(0xFF8E8E93),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${post.likeCount}',
                          style: AppTextStyles.text13Semibold(
                            context,
                            textColor: post.isLikedByMe
                                ? AppColors.primary
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // Comment Button
                InkWell(
                  onTap: onComment,
                  borderRadius: BorderRadius.circular(8.adaptSize),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.comment,
                          size: 15.adaptSize,
                          color: const Color(0xFF8E8E93),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${post.commentCount}',
                          style: AppTextStyles.text13Semibold(
                            context,
                            textColor: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // Share Button (Tracking count in database)
                InkWell(
                  onTap: onShare,
                  borderRadius: BorderRadius.circular(8.adaptSize),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.shareNodes,
                          size: 14.adaptSize,
                          color: const Color(0xFF8E8E93),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${post.shareCount}',
                          style: AppTextStyles.text13Semibold(
                            context,
                            textColor: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
