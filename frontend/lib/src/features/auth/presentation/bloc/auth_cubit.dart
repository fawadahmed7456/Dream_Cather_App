import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/cubit/safe_cubit.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/enum/app_state_status_enum.dart';
import '../../../../core/services/supabase_auth_bridge.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends SafeCubit<AuthState> {
  final AuthRepository _repository;
  final SupabaseAuthBridge _bridge;

  AuthCubit(this._repository, {SupabaseAuthBridge? bridge})
      : _bridge = bridge ?? SupabaseAuthBridge.instance,
        super(const AuthState());

  void sendOtp(String phoneNumber, {String? fullName}) async {
    emit(state.copyWith(
        status: AppStateStatus.loading,
        phoneNumber: phoneNumber,
        fullName: fullName));

    final errorMessage = await _repository.sendOtp(phoneNumber);

    if (errorMessage == null) {
      emit(state.copyWith(
          status: AppStateStatus.unauthenticated, countdownSeconds: 120));
    } else {
      emit(state.copyWith(
          status: AppStateStatus.failure, message: errorMessage));
    }
  }

  void verifyOtp(String otp) async {
    if (state.phoneNumber == null) return;

    emit(state.copyWith(status: AppStateStatus.loading));

    final errorMessage = await _repository.verifyOtp(
      phoneNumber: state.phoneNumber!,
      otp: otp,
    );

    if (errorMessage != null) {
      emit(state.copyWith(
          status: AppStateStatus.failure, message: errorMessage));
      return;
    }

    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;

    // Exchange the Firebase ID token for a Supabase session. If this fails
    // we still mark sign-in successful so the user isn't locked out — they
    // just won't be able to upload until the next retry. Storage/upload
    // code paths should look at supabaseUserId to know if the bridge ran.
    String? supabaseUserId;
    String? bridgeError;
    try {
      supabaseUserId = await _bridge.signInAfterFirebase();
      // Sync the user to our public.users table immediately so the app
      // doesn't have to wait for the first profile load to know the user
      // is "new" or "returning".
      await sl<ProfileRepository>().ensureUserExists(
        phoneNumber: state.phoneNumber!,
        fullName: state.fullName,
      );
    } catch (e) {
      bridgeError = 'Supabase session not ready: $e';
    }

    await StorageService.setLoggedIn(true);

    emit(state.copyWith(
      status: AppStateStatus.success,
      firebaseUid: firebaseUid,
      supabaseUserId: supabaseUserId,
      message: bridgeError,
    ));
  }

  void restorePhone(String phoneNumber) {
    emit(state.copyWith(
      phoneNumber: phoneNumber,
      status: AppStateStatus.unauthenticated,
      countdownSeconds: 120,
    ));
  }

  void resendOtp() async {
    if (state.phoneNumber == null) return;

    emit(state.copyWith(status: AppStateStatus.loading));
    final errorMessage = await _repository.resendOtp(state.phoneNumber!);

    if (errorMessage == null) {
      emit(state.copyWith(
          status: AppStateStatus.unauthenticated, countdownSeconds: 120));
    } else {
      emit(state.copyWith(
          status: AppStateStatus.failure, message: errorMessage));
    }
  }
}
