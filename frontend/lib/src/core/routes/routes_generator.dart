import '../../src.dart';

class RoutesGenerator {
  const RoutesGenerator._();

  static const String _tag = 'Routes';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Log.d(_tag, 'navigate → ${settings.name} args=${settings.arguments}');
    Widget page;
    switch (settings.name) {
      case Routes.kInitial:
        page = const SplashScreen();
        break;
      case Routes.kBottomNavBar:
        // navKey must be attached for static BottomNavBar.changeTab(...)
        // calls (e.g. "Find a Ride" → search tab) to resolve to a real
        // State instance instead of silently no-op'ing.
        page = BottomNavBar(key: BottomNavBar.navKey);
        break;
      case Routes.kSearchRide:
        page = const SearchRideScreen();
        break;
      case Routes.kRideListing:
        final args = settings.arguments;
        page = RideListingScreen(
          searchArgs: args is RideSearchArgs ? args : null,
        );
        break;
      case Routes.kRideDetails:
        final rideId = settings.arguments as String?;
        page = RideDetailsScreen(rideId: rideId);
        break;
      case Routes.kEditProfile:
        page = const EditProfileScreen();
        break;
      case Routes.kMyVehicles:
        page = const MyVehiclesScreen();
        break;
      case Routes.kMyRides:
        page = const MyRidesScreen();
        break;
      case Routes.kMyBookings:
        page = const MyBookingsScreen();
        break;
      case Routes.kReferAndEarn:
        page = const ReferEarnScreen();
        break;
      case Routes.kHelpAndSupport:
        page = const HelpSupportScreen();
        break;
      case Routes.kSafetyVerification:
        page = const SafetyVerificationScreen();
        break;
      case Routes.kNotifications:
        page = const NotificationsScreen();
        break;
      case Routes.kOnboarding:
        page = const OnboardingScreen();
        break;
      case Routes.kLogin:
        page = const LoginScreen();
        break;
      case Routes.kVerifyOTP:
        final args = settings.arguments;
        if (args is VerifyOTPArgs) {
          page = VerifyOTPScreen(
            phoneNumber: args.phoneNumber,
            existingCubit: args.cubit,
          );
        } else {
          // Fallback for plain String arg (e.g. deep-link).
          page = VerifyOTPScreen(phoneNumber: args as String? ?? '');
        }
        break;
      case Routes.kCompleteProfile:
        page = const CompleteProfileScreen();
        break;
      case Routes.kOfferRide:
        page = const OfferRideScreen();
        break;
      case Routes.kEditRide:
        final ride = settings.arguments;
        page = ride is Map<String, dynamic>
            ? EditRideScreen(ride: ride)
            : const Scaffold(body: Center(child: Text('No ride selected.')));
        break;
      default:
        page = const Scaffold();
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = Cubic(0.4, 0.0, 0.2, 1.0);
        final curvedAnimation =
            CurvedAnimation(parent: animation, curve: curve);

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
