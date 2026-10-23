import 'package:equatable/equatable.dart';
import '../../data/models/user_profile.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsEmailVerification,
  needsOnboarding,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserProfile? userProfile;
  final String? email;
  final String? errorMessage;
  final bool isUsernameAvailable;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userProfile,
    this.email,
    this.errorMessage,
    this.isUsernameAvailable = true,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? userProfile,
    String? email,
    String? errorMessage,
    bool? isUsernameAvailable,
  }) {
    return AuthState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      email: email ?? this.email,
      errorMessage: errorMessage,
      isUsernameAvailable: isUsernameAvailable ?? this.isUsernameAvailable,
    );
  }

  @override
  List<Object?> get props => [
        status,
        userProfile,
        email,
        errorMessage,
        isUsernameAvailable,
      ];
}
