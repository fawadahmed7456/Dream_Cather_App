import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/utils/size_utils.dart';

class ShareSheetModal extends StatelessWidget {
  final String postId;
  final VoidCallback onShareSuccess;

  const ShareSheetModal({
    super.key,
    required this.postId,
    required this.onShareSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final contacts = [
      {'name': 'Daniel Miller', 'color': Colors.amber},
      {'name': 'Chloe Armstrong', 'color': Colors.cyan},
      {'name': 'Sandy Jack', 'color': Colors.orangeAccent},
      {'name': 'Stephanie Rose', 'color': Colors.purpleAccent},
    ];

    final apps = [
      {'name': 'AirDrop', 'icon': Icons.wifi_tethering, 'color': Colors.blue},
      {'name': 'Messages', 'icon': Icons.message, 'color': Colors.green},
      {'name': 'Mail', 'icon': Icons.mail_outline, 'color': Colors.blueAccent},
      {'name': 'Notes', 'icon': Icons.edit_note, 'color': Colors.orange},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.adaptSize)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Share Post',
              style: AppTextStyles.text18Semibold(context),
            ),
            SizedBox(height: 16.h),

            // Recent Contacts row
            SizedBox(
              height: 80.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: contacts.length,
                separatorBuilder: (_, __) => SizedBox(width: 16.w),
                itemBuilder: (context, idx) {
                  final c = contacts[idx];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onShareSuccess();
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 22.adaptSize,
                          backgroundColor: c['color'] as Color,
                          child: Icon(Icons.person, color: Colors.white, size: 24.adaptSize),
                        ),
                        SizedBox(height: 6.h),
                        SizedBox(
                          width: 60.w,
                          child: Text(
                            c['name'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.text11Normal(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            // Apps row
            SizedBox(
              height: 80.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: apps.length,
                separatorBuilder: (_, __) => SizedBox(width: 16.w),
                itemBuilder: (context, idx) {
                  final a = apps[idx];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onShareSuccess();
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 22.adaptSize,
                          backgroundColor: (a['color'] as Color).withOpacity(0.15),
                          child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 22.adaptSize),
                        ),
                        SizedBox(height: 6.h),
                        SizedBox(
                          width: 60.w,
                          child: Text(
                            a['name'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.text11Normal(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}
