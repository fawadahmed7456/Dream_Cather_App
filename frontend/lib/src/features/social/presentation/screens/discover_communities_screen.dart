import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/size_utils.dart';
import '../../data/repositories/social_repository.dart';
import '../bloc/social_cubit.dart';
import 'community_feed_screen.dart';

class CommunityCategory {
  final String name;
  final String imageUrl;
  const CommunityCategory({required this.name, required this.imageUrl});
}

class DiscoverCommunitiesScreen extends StatefulWidget {
  const DiscoverCommunitiesScreen({super.key});

  @override
  State<DiscoverCommunitiesScreen> createState() => _DiscoverCommunitiesScreenState();
}

class _DiscoverCommunitiesScreenState extends State<DiscoverCommunitiesScreen> {
  final _searchController = TextEditingController();

  final List<CommunityCategory> _allCommunities = const [
    CommunityCategory(
      name: 'Single',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&q=80',
    ),
    CommunityCategory(
      name: 'Friendship',
      imageUrl: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=500&q=80',
    ),
    CommunityCategory(
      name: 'Dating',
      imageUrl: 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=500&q=80',
    ),
    CommunityCategory(
      name: 'Romantic Relationship',
      imageUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=500&q=80',
    ),
    CommunityCategory(
      name: 'Marriage',
      imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=500&q=80',
    ),
    CommunityCategory(
      name: 'Parenthood',
      imageUrl: 'https://images.unsplash.com/photo-1485546246426-74dc88dec4d9?w=500&q=80',
    ),
  ];

  late List<CommunityCategory> _filteredCommunities;

  @override
  void initState() {
    super.initState();
    _filteredCommunities = _allCommunities;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCommunities = _allCommunities;
      } else {
        _filteredCommunities = _allCommunities
            .where((c) => c.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _openCommunity(String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => SocialCubit(sl<SocialRepository>()),
          child: CommunityFeedScreen(communityName: name),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),

              // Title: Discover Communities (Matching Figma "Discover Communities")
              RichText(
                text: TextSpan(
                  text: 'Discover ',
                  style: AppTextStyles.authTitle(context),
                  children: [
                    TextSpan(
                      text: 'Communities',
                      style: AppTextStyles.authTitle(context).copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Search Box (Matching Figma Search for activities...)
              TextField(
                controller: _searchController,
                style: AppTextStyles.inputText(context),
                decoration: InputDecoration(
                  hintText: 'Search for activities...',
                  hintStyle: AppTextStyles.inputHint(context),
                  prefixIcon: Icon(Icons.search, color: const Color(0xFF9E9E9E), size: 22.adaptSize),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : const Color(0xFFF7F8FA),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.adaptSize),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.adaptSize),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Grid of Communities (Matching Figma 2-column cards)
              Expanded(
                child: GridView.builder(
                  itemCount: _filteredCommunities.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14.w,
                    mainAxisSpacing: 14.h,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, idx) {
                    final item = _filteredCommunities[idx];
                    return InkWell(
                      onTap: () => _openCommunity(item.name),
                      borderRadius: BorderRadius.circular(16.adaptSize),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.adaptSize),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: isDark ? AppColors.darkCard : const Color(0xFFE5E7EB),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: isDark ? AppColors.darkCard : const Color(0xFFE5E7EB),
                                child: const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.75),
                                  ],
                                  stops: const [0.45, 1.0],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 10.w,
                              right: 10.w,
                              bottom: 12.h,
                              child: Text(
                                item.name,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.text15Semibold(
                                  context,
                                  textColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
