import 'package:logging_utils/src/logger_sink.dart';
// ignore_for_file: constant_identifier_names

/// [LogLevel] of a [LogEntry] controls whether it appears in a log.
/// The options in increasing severity: [LogLevel.DEBUG], [LogLevel.INFO], [LogLevel.WARNING], [LogLevel.ERROR], [LogLevel.CRITICAL]
enum LogLevel { DEBUG, INFO, WARNING, ERROR, CRITICAL }

/// Controls the formatting of the timestamps in the log.
/// The options are
///   [DateTimeFMT.DATE] for year-month-day,
///   [DateTimeFMT.TIME] for hour:minute:second.microsecond
///   [DateTimeFMT.DATETIME] for year-month-day hour:minute:second.microsecond,
///   [DateTimeFMT.TS_MS] for milliseconds since epoch,
///   [DateTimeFMT.TS_US] for microseconds since epoch
enum DateTimeFMT { DATE, TIME, DATETIME, TS_MS, TS_US }

/// An entry in the log containing a single message. [LoggerSink] instances use the [asString] method to represent [LogEntry] instances.
class LogEntry {
  /// The information the [LogEntry] holds.
  final String message;

  /// The [LogLevel] of the [LogEntry].
  final LogLevel level;

  /// The time the [LogEntry] was created.
  final DateTime timeStamp;

  const LogEntry(this.message, this.level, this.timeStamp);

  /// A shorthand to create a [LogEntry] with [LogLevel.DEBUG]
  static LogEntry debug(final String message) {
    return LogEntry(message, LogLevel.DEBUG, DateTime.now());
  }

  /// A shorthand to create a [LogEntry] with [LogLevel.INFO]
  static LogEntry info(final String message) {
    return LogEntry(message, LogLevel.INFO, DateTime.now());
  }

  /// A shorthand to create a [LogEntry] with [LogLevel.WARNING]
  static LogEntry warning(final String message) {
    return LogEntry(message, LogLevel.WARNING, DateTime.now());
  }

  /// A shorthand to create a [LogEntry] with [LogLevel.ERROR]
  static LogEntry error(final String message) {
    return LogEntry(message, LogLevel.ERROR, DateTime.now());
  }

  /// A shorthand to create a [LogEntry] with [LogLevel.CRITICAL]
  static LogEntry critical(final String message) {
    return LogEntry(message, LogLevel.CRITICAL, DateTime.now());
  }

  static String _fourDigits(int n) {
    if (n >= 1000) return "$n";
    if (n >= 100) return "0$n";
    if (n >= 10) return "00$n";
    return "000$n";
  }

  static String _threeDigits(int n) {
    if (n >= 100) return "$n";
    if (n >= 10) return "0$n";
    return "00$n";
  }

  static String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  /// Creates the string representation of a [LogEntry] with respect to the selected [DateTimeFMT]
  String asString(final String loggerName, final DateTimeFMT fmt) {
    if (fmt == DateTimeFMT.DATE) {
      return "[${_fourDigits(timeStamp.year)}-${_twoDigits(timeStamp.month)}-${_twoDigits(timeStamp.day)}] [$loggerName - ${level.name.toUpperCase()}] $message";
    } else if (fmt == DateTimeFMT.TIME) {
      return "[${_twoDigits(timeStamp.hour)}:${_twoDigits(timeStamp.minute)}:${_twoDigits(timeStamp.second)}.${_threeDigits(timeStamp.millisecond)}${_threeDigits(timeStamp.microsecond)}] [$loggerName - ${level.name.toUpperCase()}] $message";
    } else if (fmt == DateTimeFMT.DATETIME) {
      return "[$timeStamp] [$loggerName - ${level.name.toUpperCase()}] $message";
    } else if (fmt == DateTimeFMT.TS_MS) {
      return "[${timeStamp.millisecondsSinceEpoch}] [$loggerName - ${level.name.toUpperCase()}] $message";
    } else if (fmt == DateTimeFMT.TS_US) {
      return "[${timeStamp.microsecondsSinceEpoch}] [$loggerName - ${level.name.toUpperCase()}] $message";
    }
    throw Exception("Not implemented DateTimeFMT: ${fmt.name}");
  }
}
