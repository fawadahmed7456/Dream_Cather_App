import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/utils/size_utils.dart';

class BlockConfirmationDialog extends StatelessWidget {
  final String username;
  final VoidCallback onConfirm;

  const BlockConfirmationDialog({
    super.key,
    required this.username,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.adaptSize)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blue circle with white X icon (as in Figma image)
            Container(
              width: 68.adaptSize,
              height: 68.adaptSize,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 38.adaptSize,
              ),
            ),

            SizedBox(height: 20.h),

            Text(
              'Are you sure?',
              style: AppTextStyles.text20Bold(context),
            ),

            SizedBox(height: 10.h),

            Text(
              'You won\'t see posts or comments from $username',
              textAlign: TextAlign.center,
              style: AppTextStyles.text14Normal(
                context,
                textColor: const Color(0xFF757575),
              ),
            ),

            SizedBox(height: 24.h),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.adaptSize),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.text14Semibold(
                        context,
                        textColor: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.adaptSize),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      'Block',
                      style: AppTextStyles.text14Semibold(
                        context,
                        textColor: Colors.white,
                      ),
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
