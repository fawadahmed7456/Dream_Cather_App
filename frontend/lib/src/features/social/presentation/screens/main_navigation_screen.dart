import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/utils/size_utils.dart';
import 'discover_communities_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DiscoverCommunitiesScreen(),
    _DummyTabScreen(title: 'Matches', icon: Icons.favorite_border),
    _DummyTabScreen(title: 'Chat', icon: Icons.chat_bubble_outline),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0xFFEFEFEF),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedLabelStyle: AppTextStyles.text11Semibold(context),
          unselectedLabelStyle: AppTextStyles.text11Normal(context),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined, size: 24.adaptSize),
              activeIcon: Icon(Icons.explore, size: 24.adaptSize),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border, size: 24.adaptSize),
              activeIcon: Icon(Icons.favorite, size: 24.adaptSize),
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 24.adaptSize),
              activeIcon: Icon(Icons.chat_bubble, size: 24.adaptSize),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 24.adaptSize),
              activeIcon: Icon(Icons.person, size: 24.adaptSize),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _DummyTabScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _DummyTabScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.text18Semibold(context)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 56.adaptSize, color: AppColors.primary.withOpacity(0.5)),
            SizedBox(height: 12.h),
            Text(title, style: AppTextStyles.text18Semibold(context)),
            SizedBox(height: 6.h),
            Text('Coming in upcoming release',
                style: AppTextStyles.helperText(context)),
          ],
        ),
      ),
    );
  }
}
