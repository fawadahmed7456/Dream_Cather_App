import 'package:equatable/equatable.dart';

/// Left-side type for `Either<Failure, T>` returned by SupabaseService and
/// feature repositories. Keep this hierarchy small — feature code should
/// switch on the concrete subtype only when it needs to render different
/// UI for, say, an auth failure vs. a network failure.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];

  @override
  String toString() => '$runtimeType: $message';
}

/// Supabase/Postgrest returned an error (RLS denial, constraint violation,
/// 4xx/5xx HTTP status, etc.). `code` is the Postgrest error code when
/// available (e.g. '42501' for RLS).
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.code, super.cause});

  final String? code;

  @override
  List<Object?> get props => [...super.props, code];
}

/// Connectivity-level failure — no route to host, DNS, socket reset, etc.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}

/// Caller is not signed in (or the bridged Supabase JWT has expired and
/// can't be refreshed). UI should send the user back to the auth flow.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause});
}

/// Payload didn't match the expected shape (missing fields, wrong type).
/// Almost always a backend/contract bug; surface to logs, not the user.
class ParsingFailure extends Failure {
  const ParsingFailure(super.message, {super.cause});
}

/// Fallback when nothing more specific fits. Prefer one of the above.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.cause});
}
