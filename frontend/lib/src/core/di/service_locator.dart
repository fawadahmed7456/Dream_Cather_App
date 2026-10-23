import 'package:get_it/get_it.dart';

import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/social/data/repositories/social_repository.dart';
import '../services/supabase_service.dart';
import '../services/supabase_storage_service.dart';
import '../utils/logger_utils.dart';

/// Global service locator. Resolve dependencies via `sl<Type>()`.
final GetIt sl = GetIt.instance;

/// Wires core services and repositories for Dream Catcher.
Future<void> setupServiceLocator() async {
  const tag = 'DI';
  Log.i(tag, 'Wiring services + repositories…');

  // Logger
  if (!sl.isRegistered<LoggerUtils>()) {
    sl.registerLazySingleton<LoggerUtils>(() => Log.instance);
  }

  // Core Supabase services
  if (!sl.isRegistered<SupabaseService>()) {
    sl.registerLazySingleton<SupabaseService>(() => SupabaseService());
  }
  if (!sl.isRegistered<SupabaseStorageService>()) {
    sl.registerLazySingleton<SupabaseStorageService>(
      () => SupabaseStorageService(),
    );
  }

  // Feature Repositories
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(() => AuthRepository());
  }
  if (!sl.isRegistered<SocialRepository>()) {
    sl.registerLazySingleton<SocialRepository>(() => SocialRepository());
  }

  Log.i(tag, 'DI complete');
}
