import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/utils/size_utils.dart';
import '../bloc/social_cubit.dart';

class CreatePostScreen extends StatefulWidget {
  final String? initialCommunity;
  const CreatePostScreen({super.key, this.initialCommunity});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _picker = ImagePicker();

  File? _mediaFile;
  String? _mediaType; // 'image' | 'video'
  bool _isSubmitting = false;
  late String _selectedCommunity;

  final List<String> _communities = [
    'Friendship',
    'Single',
    'Parenting',
    'Dating',
    'Romantic Relationship',
    'Marriage',
    'Parenthood',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCommunity = widget.initialCommunity ?? 'Friendship';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _mediaFile = File(picked.path);
        _mediaType = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _mediaFile = File(picked.path);
        _mediaType = 'video';
      });
    }
  }

  void _showMediaPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.adaptSize)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Upload Photo', style: AppTextStyles.text15Semibold(context)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_collection, color: AppColors.primary),
              title: Text('Upload Video', style: AppTextStyles.text15Semibold(context)),
              onTap: () {
                Navigator.pop(ctx);
                _pickVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.adaptSize)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8.w),
            Text(title, style: AppTextStyles.text16Semibold(context)),
          ],
        ),
        content: Text(message, style: AppTextStyles.text14Normal(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: AppTextStyles.text14Semibold(context, textColor: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Check scope: text only, text + media, or media only
    if (content.isEmpty && _mediaFile == null && title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some text or media to your post')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await context.read<SocialCubit>().createPost(
        title: title.isNotEmpty ? title : null,
        content: content.isNotEmpty ? content : null,
        mediaFile: _mediaFile,
        mediaType: _mediaType,
        community: _selectedCommunity,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post published successfully!')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Extract a clean message from Exception
      final raw = e.toString().replaceFirst('Exception: ', '');

      // Determine if it's a media-specific or general error
      final isMediaError = _mediaFile != null &&
          (raw.contains('storage') ||
              raw.contains('upload') ||
              raw.contains('bucket') ||
              raw.contains('Media') ||
              raw.contains('File'));

      _showErrorDialog(
        isMediaError ? 'Media Upload Failed' : 'Failed to Publish Post',
        raw,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorDialog('Something went wrong', 'An unexpected error occurred. Please try again.');
    }
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
        title: Text('Create A Post', style: AppTextStyles.text18Semibold(context)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Community Selector
                      Text('Community', style: AppTextStyles.inputLabel(context)),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCommunity,
                            isExpanded: true,
                            items: _communities.map((c) {
                              return DropdownMenuItem(value: c, child: Text(c, style: AppTextStyles.inputText(context)));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedCommunity = v);
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 18.h),

                      // Title Field (Matching Figma Image: Title)
                      Text('Title', style: AppTextStyles.inputLabel(context)),
                      SizedBox(height: 6.h),
                      TextField(
                        controller: _titleController,
                        style: AppTextStyles.inputText(context),
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: AppTextStyles.inputHint(context),
                          filled: true,
                          fillColor: isDark ? AppColors.darkCard : const Color(0xFFF7F8FA),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.adaptSize),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                          ),
                        ),
                      ),

                      SizedBox(height: 18.h),

                      // Description Field (Matching Figma Image: Description...)
                      Text('Description', style: AppTextStyles.inputLabel(context)),
                      SizedBox(height: 6.h),
                      TextField(
                        controller: _contentController,
                        maxLines: 5,
                        style: AppTextStyles.inputText(context),
                        decoration: InputDecoration(
                          hintText: 'Description...',
                          hintStyle: AppTextStyles.inputHint(context),
                          filled: true,
                          fillColor: isDark ? AppColors.darkCard : const Color(0xFFF7F8FA),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.adaptSize),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Selected Media Preview or "+ Add photos and videos" dashed box (Matching Figma)
                      if (_mediaFile != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.adaptSize),
                              child: _mediaType == 'video'
                                  ? Container(
                                      height: 180.h,
                                      width: double.infinity,
                                      color: Colors.black87,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.video_file, color: Colors.white, size: 48.adaptSize),
                                          SizedBox(height: 8.h),
                                          Text('Video Selected', style: AppTextStyles.text14Normal(context, textColor: Colors.white)),
                                        ],
                                      ),
                                    )
                                  : Image.file(
                                      _mediaFile!,
                                      height: 180.h,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 8.h,
                              right: 8.w,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _mediaFile = null;
                                  _mediaType = null;
                                }),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  padding: EdgeInsets.all(6.adaptSize),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        InkWell(
                          onTap: _showMediaPickerSheet,
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          child: Container(
                            width: double.infinity,
                            height: 64.h,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12.adaptSize),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.4),
                                width: 1.5,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 20.adaptSize),
                                SizedBox(width: 8.w),
                                Text(
                                  '+ Add photos and videos',
                                  style: AppTextStyles.text14Semibold(context, textColor: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Post Button (Matching Figma: Blue full-width "Post" button)
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.adaptSize)),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 22.adaptSize,
                          height: 22.adaptSize,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text('Post', style: AppTextStyles.primaryButton(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
