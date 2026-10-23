import '../../../../core/enum/app_state_status_enum.dart';

class AuthState {
  final AppStateStatus status;
  final String? phoneNumber;
  final String? fullName;
  final int countdownSeconds;
  final String? message;

  /// Firebase Auth UID (set after a successful OTP verification).
  final String? firebaseUid;

  /// public.users.id returned by the firebase-bridge function. This is the
  /// value `auth.uid()` will return inside RLS evaluations after the
  /// Supabase session is opened. Use this — NOT firebaseUid — as the
  /// storage path prefix.
  final String? supabaseUserId;

  const AuthState({
    this.status = AppStateStatus.initial,
    this.phoneNumber,
    this.fullName,
    this.countdownSeconds = 0,
    this.message,
    this.firebaseUid,
    this.supabaseUserId,
  });

  bool get isLoading => status == AppStateStatus.loading;

  AuthState copyWith({
    AppStateStatus? status,
    String? phoneNumber,
    String? fullName,
    int? countdownSeconds,
    String? message,
    String? firebaseUid,
    String? supabaseUserId,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      message: message ?? this.message,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      supabaseUserId: supabaseUserId ?? this.supabaseUserId,
    );
  }
}
