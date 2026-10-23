import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/utils/size_utils.dart';

class PostVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const PostVideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<PostVideoPlayerWidget> createState() => _PostVideoPlayerWidgetState();
}

class _PostVideoPlayerWidgetState extends State<PostVideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      }).catchError((_) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200.h,
        alignment: Alignment.center,
        color: Colors.black12,
        child: const Icon(Icons.error_outline, color: Colors.grey),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 220.h,
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.adaptSize),
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio > 0
              ? _controller.value.aspectRatio
              : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              if (!_controller.value.isPlaying)
                Container(
                  width: 50.adaptSize,
                  height: 50.adaptSize,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32.adaptSize,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
