import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Base cubit that handles safe state emission and automatic cleanup
/// All your cubits should extend this instead of Cubit
abstract class SafeCubit<State> extends Cubit<State> {
  /// Safe Cubit
  SafeCubit(super.initialState);

  // Track subscriptions and timers for automatic cleanup
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];

  /// Override emit to make it safe by default
  @override
  void emit(State state) {
    if (!isClosed) {
      super.emit(state);
    } else {
      if (kDebugMode) {
        debugPrint(
          '⚠️ $runtimeType: Attempted to emit after close - safely ignored',
        );
      }
    }
  }

  /// Register a subscription for automatic cleanup
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Register a timer for automatic cleanup
  void addTimer(Timer timer) {
    _timers.add(timer);
  }

  /// Helper for safe async operations with automatic cancellation
  Future<T?> safeAsync<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      return isClosed ? null : result;
    } catch (e) {
      if (!isClosed) rethrow;
      return null;
    }
  }

  @override
  Future<void> close() {
    // Auto-cancel all registered subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Auto-cancel all registered timers
    for (var timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    return super.close();
  }
}
