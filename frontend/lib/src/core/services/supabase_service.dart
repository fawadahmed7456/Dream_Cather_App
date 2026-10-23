import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/failures.dart';
import '../utils/logger_utils.dart';

/// Centralised access point to Supabase. Feature code MUST go through this
/// service (usually via a thin per-feature repository) rather than
/// reaching for `Supabase.instance.client` directly — that lets us swap
/// the backend, mock it in tests, and route every call through one place
/// for logging, retries, and Failure mapping.
///
/// The service exposes the raw `SupabaseClient` for the few cases where
/// streaming or realtime subscriptions are needed, but the day-to-day
/// surface is [run], which wraps any Supabase call in `Either<Failure, T>`
/// and translates the SDK's exception zoo into the [Failure] hierarchy.
class SupabaseService {
  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Escape hatch for realtime/stream/storage code that needs the raw
  /// client. Prefer [run] for one-shot REST calls.
  SupabaseClient get client => _client;

  /// Returns a Postgrest query builder for [table]. Wrap the chained
  /// query in [run] to get `Either<Failure, T>` back.
  ///
  /// Example:
  /// ```dart
  /// final result = await service.run(
  ///   () => service.from('rides').select().eq('status', 'active'),
  /// );
  /// ```
  SupabaseQueryBuilder from(String table) => _client.from(table);

  static const String _tag = 'SupabaseService';

  /// Executes [action] and maps any thrown exception to a [Failure]. The
  /// action is typically a Postgrest builder future, an RPC call, or an
  /// auth call — anything that talks to Supabase.
  Future<Either<Failure, T>> run<T>(
    FutureOr<T> Function() action,
  ) async {
    try {
      final value = await action();
      return Right(value);
    } on PostgrestException catch (e, st) {
      Log.e(_tag, 'Postgrest ${e.code}: ${e.message}', e, st);
      return Left(_fromPostgrest(e));
    } on AuthException catch (e, st) {
      Log.e(_tag, 'Auth: ${e.message}', e, st);
      return Left(AuthFailure(e.message, cause: e));
    } on StorageException catch (e, st) {
      Log.e(_tag, 'Storage ${e.statusCode}: ${e.message}', e, st);
      return Left(ServerFailure(e.message, code: e.statusCode, cause: e));
    } on SocketException catch (e, st) {
      Log.e(_tag, 'Network: ${e.message}', e, st);
      return Left(NetworkFailure(e.message, cause: e));
    } on TimeoutException catch (e, st) {
      Log.e(_tag, 'Timeout', e, st);
      return Left(NetworkFailure('Request timed out', cause: e));
    } on FormatException catch (e, st) {
      Log.e(_tag, 'Parsing: ${e.message}', e, st);
      return Left(ParsingFailure(e.message, cause: e));
    } catch (e, st) {
      Log.e(_tag, 'Unknown: $e', e, st);
      return Left(UnknownFailure(e.toString(), cause: e));
    }
  }

  Failure _fromPostgrest(PostgrestException e) {
    // 42501 = insufficient_privilege (RLS denial). Surface as AuthFailure
    // so the UI can prompt re-auth rather than show a generic server error.
    if (e.code == '42501' || e.code == 'PGRST301') {
      return AuthFailure(e.message, cause: e);
    }
    return ServerFailure(e.message, code: e.code, cause: e);
  }
}
