import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Base bloc that handles safe event addition and automatic cleanup
/// All your blocs should extend this instead of Bloc
abstract class SafeBloc<Event, State> extends Bloc<Event, State> {
  SafeBloc(super.initialState);

  // Track subscriptions and timers for automatic cleanup
  final Set<StreamSubscription> _subscriptions = {};
  final Set<Timer> _timers = {};

  /// Override add to make it safe by default
  @override
  void add(Event event) {
    if (!isClosed) {
      super.add(event);
    } else {
      if (kDebugMode) {
        debugPrint(
          '⚠️ $runtimeType: Attempted to add event after close - safely ignored',
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

  /// Helper for safe async operations
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
