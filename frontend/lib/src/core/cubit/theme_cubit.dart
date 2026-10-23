import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/storage_service.dart';

enum ThemeOption { light, dark }

class ThemeCubit extends Cubit<ThemeOption> {
  ThemeCubit() : super(_initialTheme);

  static ThemeOption get _initialTheme {
    final isDark = StorageService.isDarkTheme;
    if (isDark == null) return ThemeOption.light;
    return isDark ? ThemeOption.dark : ThemeOption.light;
  }

  void toggleTheme() {
    final newState =
        state == ThemeOption.light ? ThemeOption.dark : ThemeOption.light;
    StorageService.setDarkTheme(newState == ThemeOption.dark);
    emit(newState);
  }

  void setLightTheme() {
    StorageService.setDarkTheme(false);
    emit(ThemeOption.light);
  }

  void setDarkTheme() {
    StorageService.setDarkTheme(true);
    emit(ThemeOption.dark);
  }
}
