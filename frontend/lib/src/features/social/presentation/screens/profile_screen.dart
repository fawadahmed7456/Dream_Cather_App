import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/cubit/theme_cubit.dart';
import '../../../../core/routes/routes_constants.dart';
import '../../../../core/utils/size_utils.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = 'User';
  String _email = '';
  String _avatarUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _email = user.email ?? '';
        final res = await Supabase.instance.client
            .from('users')
            .select('full_name, username, avatar_url')
            .eq('id', user.id)
            .maybeSingle();

        if (res != null && mounted) {
          final fullName = res['full_name'] as String?;
          final username = res['username'] as String?;
          _displayName = (fullName != null && fullName.isNotEmpty)
              ? fullName
              : (username != null && username.isNotEmpty ? username : 'User');
          _avatarUrl = res['avatar_url'] as String? ?? '';
        }
      }
    } catch (_) {
      // Keep default fallback
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of Dream Catcher?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthCubit>().signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.kGetStarted,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.text18Semibold(context)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 12.h),

                  // Avatar
                  CircleAvatar(
                    radius: 46.adaptSize,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage: _avatarUrl.isNotEmpty
                        ? NetworkImage(_avatarUrl)
                        : null,
                    child: _avatarUrl.isEmpty
                        ? Icon(Icons.person, size: 52.adaptSize, color: AppColors.primary)
                        : null,
                  ),

                  SizedBox(height: 16.h),

                  // Name
                  Text(
                    _displayName,
                    style: AppTextStyles.text20Bold(context),
                  ),

                  if (_email.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      _email,
                      style: AppTextStyles.text14Normal(context).copyWith(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],

                  SizedBox(height: 32.h),

                  // Menu card container
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16.adaptSize),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFEFEFEF),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildTile(
                          icon: Icons.person_outline,
                          title: 'Account Information',
                          onTap: () {},
                        ),
                        Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFF0F0F0)),
                        _buildTile(
                          icon: Icons.notifications_none,
                          title: 'Notifications',
                          onTap: () {},
                        ),
                        Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFF0F0F0)),
                        _buildTile(
                          icon: Icons.shield_outlined,
                          title: 'Privacy & Security',
                          onTap: () {},
                        ),
                        Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFF0F0F0)),
                        BlocBuilder<ThemeCubit, ThemeOption>(
                          builder: (context, themeOption) {
                            final isDarkMode = themeOption == ThemeOption.dark;
                            return ListTile(
                              leading: Icon(
                                isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                                color: AppColors.primary,
                                size: 22.adaptSize,
                              ),
                              title: Text('Dark Mode', style: AppTextStyles.text14Normal(context)),
                              trailing: Switch(
                                value: isDarkMode,
                                activeColor: AppColors.primary,
                                onChanged: (_) {
                                  context.read<ThemeCubit>().toggleTheme();
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Logout Button
                  InkWell(
                    onTap: _handleLogout,
                    borderRadius: BorderRadius.circular(14.adaptSize),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14.adaptSize),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                          SizedBox(width: 8.w),
                          Text(
                            'Log Out',
                            style: AppTextStyles.text15Semibold(
                              context,
                              textColor: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22.adaptSize),
      title: Text(title, style: AppTextStyles.text14Normal(context)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
