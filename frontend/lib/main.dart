import 'package:safar_share/src/src.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Log.i('Boot', 'Cold start');

  try {
    Log.i('Boot', '[1/4] Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Log.i('Boot', '[1/4] Firebase OK');
  } catch (e) {
    Log.e('Boot', '[1/4] Firebase FAILED: $e');
  }

  if (AppConfig.devAuthEnabled) {
    Log.w('Boot',
        'Dev auth override active - Firebase OTP will be skipped; user=${AppConfig.devSupabaseUserId}');
  }

  try {
    Log.i('Boot', '[2/4] Initializing Supabase...');
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    Log.i('Boot', '[2/4] Supabase OK (${AppConfig.supabaseUrl})');
  } catch (e) {
    Log.e('Boot', '[2/4] Supabase FAILED: $e');
  }

  try {
    Log.i('Boot', '[3/4] Initializing StorageService...');
    await StorageService.init();
    Log.i('Boot', '[3/4] StorageService OK');
  } catch (e) {
    Log.e('Boot', '[3/4] StorageService FAILED: $e');
  }

  try {
    Log.i('Boot', '[4/4] Setting up service locator...');
    await setupServiceLocator();
    Log.i('Boot', '[4/4] Service locator OK');
  } catch (e) {
    Log.e('Boot', '[4/4] Service locator FAILED: $e');
  }

  runApp(const SafarShare());
  Log.i('Boot', 'runApp dispatched');
}
