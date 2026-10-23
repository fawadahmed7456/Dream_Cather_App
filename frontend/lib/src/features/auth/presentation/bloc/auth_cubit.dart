import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger_utils.dart';
import '../../../../core/utils/storage_service.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit(this._repository) : super(const AuthState());

  static const String _tag = 'AuthCubit';

  /// Check existing session on app startup
  Future<void> checkAuthStatus() async {
    final authUser = _repository.currentAuthUser;
    if (authUser == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }

    final isVerified = _repository.isEmailVerified;
    if (!isVerified) {
      emit(state.copyWith(
        status: AuthStatus.needsEmailVerification,
        email: authUser.email,
      ));
      return;
    }

    final profile = await _repository.fetchUserProfile(authUser.id);
    if (profile == null || profile.username.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.needsOnboarding,
        email: authUser.email,
      ));
      return;
    }

    await StorageService.setLoggedIn(true);
    emit(state.copyWith(
      status: AuthStatus.authenticated,
      userProfile: profile,
      email: authUser.email,
    ));
  }

  /// Sign up with email & password
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final res = await _repository.signUp(email: email, password: password);
      final user = res.user;

      // In Supabase, if the user is already registered, identities will be empty
      // and Supabase will NOT send a duplicate confirmation email.
      if (user != null && user.identities != null && user.identities!.isEmpty) {
        Log.i(_tag, 'User already exists. Attempting sign-in with password...');
        try {
          final signInRes = await _repository.signIn(email: email, password: password);
          final authedUser = signInRes.user;
          if (authedUser != null) {
            if (authedUser.emailConfirmedAt == null) {
              emit(state.copyWith(
                status: AuthStatus.needsEmailVerification,
                email: email,
              ));
            } else {
              final profile = await _repository.fetchUserProfile(authedUser.id);
              if (profile == null || profile.username.isEmpty) {
                emit(state.copyWith(
                  status: AuthStatus.needsOnboarding,
                  email: email,
                ));
              } else {
                await StorageService.setLoggedIn(true);
                emit(state.copyWith(
                  status: AuthStatus.authenticated,
                  userProfile: profile,
                  email: email,
                ));
              }
            }
            return;
          }
        } catch (_) {
          emit(state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'This email is already registered. Please go to Sign In.',
          ));
          return;
        }
      }

      // If user requires email confirmation
      if (user != null && user.emailConfirmedAt == null) {
        emit(state.copyWith(
          status: AuthStatus.needsEmailVerification,
          email: email,
        ));
      } else {
        // Direct onboarding
        emit(state.copyWith(
          status: AuthStatus.needsOnboarding,
          email: email,
        ));
      }
    } catch (e) {
      Log.e(_tag, 'SignUp error: $e');
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Sign in with email & password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final res = await _repository.signIn(email: email, password: password);
      final user = res.user;

      if (user == null) {
        emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Sign in failed. Please try again.',
        ));
        return;
      }

      if (user.emailConfirmedAt == null) {
        emit(state.copyWith(
          status: AuthStatus.needsEmailVerification,
          email: email,
        ));
        return;
      }

      final profile = await _repository.fetchUserProfile(user.id);
      if (profile == null || profile.username.isEmpty) {
        emit(state.copyWith(
          status: AuthStatus.needsOnboarding,
          email: email,
        ));
        return;
      }

      await StorageService.setLoggedIn(true);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        userProfile: profile,
        email: email,
      ));
    } catch (e) {
      Log.e(_tag, 'SignIn error: $e');
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Resend confirmation email
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _repository.resendVerificationEmail(email);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// Check username availability live
  Future<bool> checkUsernameAvailable(String username) async {
    final available = await _repository.isUsernameAvailable(username);
    emit(state.copyWith(isUsernameAvailable: available));
    return available;
  }

  /// Save profile during onboarding registration
  Future<bool> completeOnboarding(UserProfile profile) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final saved = await _repository.saveUserProfile(profile);
      await StorageService.setLoggedIn(true);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        userProfile: saved,
      ));
      return true;
    } catch (e) {
      Log.e(_tag, 'completeOnboarding error: $e');
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _repository.signOut();
    await StorageService.setLoggedIn(false);
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
