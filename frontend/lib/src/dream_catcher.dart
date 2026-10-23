import 'package:flutter_localizations/flutter_localizations.dart';
import 'src.dart';

class DreamCatcher extends StatelessWidget {
  const DreamCatcher({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(create: (context) => LocaleCubit()),
        BlocProvider(create: (context) => AuthCubit(sl<AuthRepository>())),
      ],
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return BlocBuilder<ThemeCubit, ThemeOption>(
              builder: (context, themeState) {
                return SizerUtils(
                  builder: (context, orientation) => MaterialApp(
                    title: 'Dream Catcher',
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeState == ThemeOption.dark
                        ? ThemeMode.dark
                        : ThemeMode.light,
                    locale: locale,
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: const [
                      Locale('en', ''),
                    ],
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

/// DreamCatcherApp alias
typedef DreamCatcherApp = DreamCatcher;
