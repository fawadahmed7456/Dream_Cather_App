import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:safar_share/l10n/app_localizations.dart';
import 'src.dart';

class SafarShare extends StatelessWidget {
  const SafarShare({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(create: (context) => LocaleCubit()),
        BlocProvider(create: (context) => sl<NotificationCubit>()..init()),
      ],
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return BlocBuilder<ThemeCubit, ThemeOption>(
              builder: (context, themeState) {
                // Mount the responsive sizing system ABOVE MaterialApp so the
                // `.w` / `.h` / `.fSize` / `.adaptSize` extensions resolve
                // against the real device size everywhere — including the
                // ThemeData built below — and re-resolve on rotation / resize.
                return SizerUtils(
                  builder: (context, orientation) => MaterialApp(
                    title: 'SafarShare',
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeState == ThemeOption.light
                        ? ThemeMode.light
                        : ThemeMode.dark,
                    locale: locale,
                    localizationsDelegates: [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: AppLocalizations.supportedLocales,
                    debugShowCheckedModeBanner: false,
                    initialRoute: Routes.kInitial,
                    onGenerateRoute: RoutesGenerator.onGenerateRoute,
                    scrollBehavior: const ScrollBehavior().copyWith(
                      overscroll: false,
                      physics: const BouncingScrollPhysics(),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
