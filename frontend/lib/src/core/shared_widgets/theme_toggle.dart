import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safar_share/src/src.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<ThemeCubit>().toggleTheme();
      },
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.adaptSize),
          border: Border.all(color: context.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          context.isDarkMode ? FontAwesomeIcons.sun : FontAwesomeIcons.moon,
          size: 20.adaptSize,
          color: context.colorScheme.onSurface,
        ),
      ),
    );
  }
}
