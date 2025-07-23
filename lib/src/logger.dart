import 'dart:async';

import 'package:logging_utils/src/log_entry.dart';
import 'package:logging_utils/src/logger_sink.dart';

/// Root logger, preconfigured to log in the terminal
final Logger logging =
    Logger(loggerName: "ROOT", sink: ConsoleSink(), loggerCallback: null);

/// Logger class
///
/// Based on assigned [LoggerSink] it can log in the terminal, to a file or to a remote through a network using [CustomSink].
/// The [Logger] can be listened to, using the provided loggerCallback. All [LogEntry] instances above sinkLevel are flushed in batches of flushInterval apart.
/// Defaults: 1000 ms flushInterval, warning sinkLevel and DateTime formatting
class Logger {
  List<LogEntry> _buffer = [];
  bool _isActive = false;
  Timer? _timer;
  LoggerSink _sink;
  String _loggerName;
  void Function(LogEntry)? _loggerCallback;
  int _flushInterval = 1000;
  LogLevel _sinkLevel = LogLevel.WARNING;
  DateTimeFMT _fmt = DateTimeFMT.DATETIME;

  Logger(
      {required String loggerName,
      required LoggerSink sink,
      required void Function(LogEntry)? loggerCallback})
      : _loggerCallback = loggerCallback,
        _sink = sink,
        _loggerName = loggerName;

  /// Modifies the interval with which the [LoggerSink] flushes [LogEntry] instances.
  void setFlushInterval(final int intervalMs) async {
    _sleep();
    _flushInterval = intervalMs;
    if (_isActive) {
      _wake();
    }
  }

  /// Modifies the [LoggerSink] of this logger.
  void setLoggerSink(final LoggerSink sink) {
    _sleep();
    _sink = sink;
    if (_isActive) {
      _wake();
    }
  }

  /// Modifies the name of this logger in the log.
  void setLoggerName(final String loggerName){
    _sleep();
    _loggerName = loggerName;
    if (_isActive) {
      _wake();
    }
  }

  /// Modifies the [LogLevel] below which [LogEntry] instances are ignored.
  void setLoggerSinkLevel(final LogLevel level){   
    _sleep();
    _sinkLevel = level;
    if (_isActive) {
      _wake();
    }
  }

  /// Modifies the callback to be called when [LogEntry] instances are added
  void setLoggerCallback(final void Function(LogEntry)? loggerCallback){
    _sleep();
    _loggerCallback = loggerCallback;
    if (_isActive) {
      _wake();
    }
  }

  /// Modifies the time formatting in the log
  void setDateTimeFMT(final DateTimeFMT fmt){
    _sleep();
    _fmt = fmt;
    if (_isActive) {
      _wake();
    }
  }

  /// Activates the [Logger]
  void start() {
    if (_isActive) {
      return;
    }

    _sink.start();

    _isActive = true;
    _timer =
        Timer.periodic(Duration(milliseconds: _flushInterval), ((timer) async {
      await _flush();
    }));
  }

  /// Deactivates the [Logger], all as of yet unflushed [LogEntry] instances are flushed by the time this future finalizes.
  Future<void> stop() async {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    _timer?.cancel();
    await _flush();
  }

  void _sleep() {
    _timer?.cancel();
  }

  void _wake() {
    if (_timer?.isActive ?? false) {
      return;
    }
    _timer =
        Timer.periodic(Duration(milliseconds: _flushInterval), ((timer) async {
      await _flush();
    }));
  }

  /// Add a [LogEntry] with [LogLevel.DEBUG] level
  void debug(final String message) {
    if (!_isActive) {
      return;
    }
    add(LogEntry(message, LogLevel.DEBUG, DateTime.now()));
  }

  /// Add a [LogEntry] with [LogLevel.INFO] level
  void info(final String message) {
    if (!_isActive) {
      return;
    }
    add(LogEntry(message, LogLevel.INFO, DateTime.now()));
  }

  /// Add a [LogEntry] with [LogLevel.WARNING] level
  void warning(final String message) {
    if (!_isActive) {
      return;
    }
    add(LogEntry(message, LogLevel.WARNING, DateTime.now()));
  }

  /// Add a [LogEntry] with [LogLevel.ERROR] level
  void error(final String message) {
    if (!_isActive) {
      return;
    }
    add(LogEntry(message, LogLevel.ERROR, DateTime.now()));
  }

  /// Add a [LogEntry] with [LogLevel.CRITICAL] level
  void critical(final String message) {
    if (!_isActive) {
      return;
    }
    add(LogEntry(message, LogLevel.CRITICAL, DateTime.now()));
  }

  /// Adds [LogEntry] instances in a batch
  void addAll(final List<LogEntry> entries) {
    _buffer.addAll(entries);
    if (entries.isNotEmpty) {
      _wake();
    }
    if (_loggerCallback != null) {
      entries.forEach(_loggerCallback!);
    }
  }

  /// Adds a [LogEntry] instance
  void add(final LogEntry entry) {
    _buffer.add(entry);
    _wake();
    if (_loggerCallback != null) {
      _loggerCallback!(entry);
    }
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) {
      _sleep();
      return;
    }

    final List<LogEntry> copy = _buffer;
    await _sink.flush(
        copy.where((e) => e.level.index >= _sinkLevel.index).toList(),
        _loggerName,
        _fmt);
    _buffer = _buffer.skip(copy.length).toList();
  }
}

// create loggerbase

// extend asynclogger + typedef logger asynclogger
// extend threadedlogger