import 'package:logger/logger.dart';

/// Single logger used by everything in the app. Wraps `package:logger`
/// with a tag-first API so each call site reads like
/// `Log.i('HomeBloc', 'Loading stats for $userId')`.
///
/// Use [Log.d]/[Log.i]/[Log.w]/[Log.e] from anywhere — the underlying
/// [LoggerUtils] is also registered in `get_it` for tests that want to
/// inject a fake.
class Log {
  const Log._();

  static final LoggerUtils _instance = LoggerUtils(_buildLogger());

  /// Use this in `setupServiceLocator` if you want `sl<LoggerUtils>()`.
  static LoggerUtils get instance => _instance;

  static void d(String tag, String message) => _instance.log(tag, message);

  static void i(String tag, String message) => _instance.logInfo(tag, message);

  static void w(String tag, String message) =>
      _instance.logWarning(tag, message);

  static void e(String tag, String message, [Object? error, StackTrace? st]) =>
      _instance.logError(tag, message, error, st);

  static Logger _buildLogger() {
    return Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 100,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
  }
}

/// A [LoggerUtils] class for logging messages with different severity levels.
class LoggerUtils {
  final Logger _logger;

  LoggerUtils(this._logger);

  /// Debug-level log. Filtered out in release builds.
  void log(String tag, String message) => _logger.d('[$tag] $message');

  /// Info-level log.
  void logInfo(String tag, String message) => _logger.i('[$tag] $message');

  /// Warning-level log.
  void logWarning(String tag, String message) => _logger.w('[$tag] $message');

  /// Error-level log. Pass [error] + optional [stackTrace] so the
  /// pretty printer can format them properly.
  void logError(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) =>
      _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);
}
