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
      case Routes.kGetStarted:
        page = const GetStartedScreen();
        break;
      case Routes.kLogin:
        page = const LoginScreen();
        break;
      case Routes.kSignUp:
        page = const SignUpScreen();
        break;
      case Routes.kHouseRules:
        page = const HouseRulesScreen();
        break;
      case Routes.kEmailVerification:
        final arg = settings.arguments;
        if (arg is EmailVerificationArgs) {
          page = EmailVerificationScreen(
            email: arg.email,
            password: arg.password,
          );
        } else {
          page = EmailVerificationScreen(
            email: arg as String? ?? '',
          );
        }
        break;
      case Routes.kOnboarding:
        page = const OnboardingWizardScreen();
        break;
      case Routes.kBottomNavBar:
      case Routes.kHome:
        page = const MainNavigationScreen();
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
        page = const Scaffold(body: Center(child: Text('Offer Ride')));
        break;
      case Routes.kEditRide:
        page = const Scaffold(body: Center(child: Text('Edit Ride')));
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
