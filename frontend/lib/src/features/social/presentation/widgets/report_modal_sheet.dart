import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/utils/size_utils.dart';

class ReportModalSheet extends StatefulWidget {
  final String postId;
  const ReportModalSheet({super.key, required this.postId});

  @override
  State<ReportModalSheet> createState() => _ReportModalSheetState();
}

class _ReportModalSheetState extends State<ReportModalSheet> {
  final List<String> _reasons = [
    'Inappropriate content',
    'Hate',
    'Copyright violation',
    'Misleading or harmful information',
    'Harassment',
    'Self-harm/Violence',
    'Fake identity/Impersonation',
    'Commercial transaction',
    'Prohibited advertisement',
    'Other',
  ];

  String? _selectedReason = 'Inappropriate content';
  final _detailsController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_submitted) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.adaptSize)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60.adaptSize,
              height: 60.adaptSize,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 36.adaptSize),
            ),
            SizedBox(height: 16.h),
            Text(
              'Thank You!',
              style: AppTextStyles.text20Bold(context),
            ),
            SizedBox(height: 8.h),
            Text(
              'Thanks for looking out for yourself and your fellow members. Our moderation team will investigate this report.',
              textAlign: TextAlign.center,
              style: AppTextStyles.text14Normal(
                context,
                textColor: const Color(0xFF757575),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.adaptSize),
                  ),
                ),
                child: Text('Done', style: AppTextStyles.primaryButton(context)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.adaptSize)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
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
              'Report An Issue',
              style: AppTextStyles.text18Semibold(context),
            ),
            SizedBox(height: 8.h),
            Text(
              'Thanks for looking out for yourself and your fellow members. Select what\'s happening and we\'ll take action.',
              style: AppTextStyles.text14Normal(
                context,
                textColor: const Color(0xFF757575),
              ),
            ),
            SizedBox(height: 16.h),

            // Chips of reasons (as in Figma image)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _reasons.map((r) {
                        final isSel = _selectedReason == r;
                        return ChoiceChip(
                          label: Text(r),
                          selected: isSel,
                          onSelected: (_) => setState(() => _selectedReason = r),
                          selectedColor: AppColors.primary,
                          labelStyle: AppTextStyles.text12Semibold(
                            context,
                            textColor: isSel ? Colors.white : const Color(0xFF4A4A4A),
                          ),
                          backgroundColor: const Color(0xFFF4F5F7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.adaptSize),
                            side: BorderSide(
                              color: isSel ? AppColors.primary : const Color(0xFFE5E7EB),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: _detailsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Additional details (optional)...',
                        hintStyle: AppTextStyles.inputHint(context),
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 12.h),

            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _submitted = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.adaptSize),
                  ),
                ),
                child: Text('Submit Report', style: AppTextStyles.primaryButton(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
