import 'package:dream_catcher/src/src.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Log.i('Boot', 'Cold start - Dream Catcher');

  try {
    Log.i('Boot', '[1/3] Initializing Supabase...');
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    Log.i('Boot', '[1/3] Supabase OK (${AppConfig.supabaseUrl})');
  } catch (e) {
    Log.e('Boot', '[1/3] Supabase FAILED: $e');
  }

  try {
    Log.i('Boot', '[2/3] Initializing StorageService...');
    await StorageService.init();
    Log.i('Boot', '[2/3] StorageService OK');
  } catch (e) {
    Log.e('Boot', '[2/3] StorageService FAILED: $e');
  }

  try {
    Log.i('Boot', '[3/3] Setting up service locator...');
    await setupServiceLocator();
    Log.i('Boot', '[3/3] Service locator OK');
  } catch (e) {
    Log.e('Boot', '[3/3] Service locator FAILED: $e');
  }

  runApp(const SafarShare());
  Log.i('Boot', 'runApp dispatched');
}
