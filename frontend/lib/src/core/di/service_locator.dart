import 'package:get_it/get_it.dart';

import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/bookings/data/repositories/bookings_repository.dart';
import '../../features/home/data/repositories/home_repository.dart';
import '../../features/notifications/notifications.dart';
import '../../features/profile/data/repositories/profile_repository.dart';
import '../../features/reviews/data/repositories/reviews_repository.dart';
import '../../features/wallet/data/repositories/wallet_repository.dart';
import '../../features/profile/data/repositories/vehicles_repository.dart';
import '../../features/ride_listing/data/repositories/rides_repository.dart';
import '../services/supabase_auth_bridge.dart';
import '../services/supabase_service.dart';
import '../services/supabase_storage_service.dart';
import '../utils/logger_utils.dart';

/// Global service locator. Resolve dependencies via `sl<Type>()`.
final GetIt sl = GetIt.instance;

/// Wires every cross-cutting service and repository. Call once from
/// `main()` AFTER `Supabase.initialize` so [SupabaseService] can grab the
/// initialised client.
///
/// Adding a new service?
///   - Singleton: shared state lives in the instance (e.g. caches).
///   - LazySingleton: instance is created on first lookup.
///   - Factory: a fresh instance per `sl<T>()` call.
Future<void> setupServiceLocator() async {
  const tag = 'DI';
  Log.i(tag, 'Wiring services + repositories…');

  // Logger first so anything that touches sl<LoggerUtils>() at boot works.
  if (!sl.isRegistered<LoggerUtils>()) {
    sl.registerLazySingleton<LoggerUtils>(() => Log.instance);
  }

  // -- core services -------------------------------------------------------
  sl.registerLazySingleton<SupabaseService>(() => SupabaseService());
  sl.registerLazySingleton<SupabaseStorageService>(
    () => SupabaseStorageService(),
  );
  // The bridge is a process-wide singleton because it caches the JWT.
  sl.registerLazySingleton<SupabaseAuthBridge>(
    () => SupabaseAuthBridge.instance,
  );

  // -- feature repositories ------------------------------------------------
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository());
  sl.registerLazySingleton<RidesRepository>(() => RidesRepository(sl()));
  sl.registerLazySingleton<BookingsRepository>(
    () => BookingsRepository(sl()),
  );
  sl.registerLazySingleton<HomeRepository>(() => HomeRepository());
  sl.registerLazySingleton<VehiclesRepository>(() => VehiclesRepository());
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepository());
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepository(),
  );
  sl.registerLazySingleton<WalletRepository>(() => WalletRepository());
  sl.registerLazySingleton<ReviewsRepository>(() => ReviewsRepository());

  // -- cubits --------------------------------------------------------------
  sl.registerFactory<NotificationCubit>(() => NotificationCubit(sl()));

  Log.i(tag, 'DI complete');
}
