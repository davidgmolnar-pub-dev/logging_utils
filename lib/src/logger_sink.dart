import 'dart:io';

import 'package:logging_utils/src/log_entry.dart';

/// Specifies whether [LoggerSink] instances that - among others - log to a file, should clear the file on [LoggerSink.start]
enum FileSinkStartBehavior {
  // ignore: constant_identifier_names
  CLEAR,
  // ignore: constant_identifier_names
  KEEP
}

/// Base class of all [LoggerSink] derivatives to enforce [LoggerSink.flush] and [LoggerSink.start] to exist.
abstract class LoggerSink {
  Future<void> flush(final List<LogEntry> entries, final String loggerName,
      final DateTimeFMT fmt);

  void flushSync(final List<LogEntry> entries, final String loggerName,
      final DateTimeFMT fmt);

  void start();
}

/// A [LoggerSink] that logs to the terminal
class ConsoleSink extends LoggerSink {
  /// Flushes all received [LogEntry] instances to the terminal
  @override
  Future<void> flush(final List<LogEntry> entries, final String loggerName,
      final DateTimeFMT fmt) async {
    print(entries.map((e) => e.asString(loggerName, fmt)).join("\n"));
  }

  /// Synchronously flushes all received [LogEntry] instances to the terminal
  @override
  void flushSync(List<LogEntry> entries, String loggerName, DateTimeFMT fmt) =>
      flush(entries, loggerName, fmt);

  /// No startup behavior for a [ConsoleSink]
  @override
  void start() {}
}

/// A [LoggerSink] that logs a file
class FileSink extends LoggerSink {
  /// The file path of the log
  final String filename;

  /// Specifies whether the [FileSink] should clear the file on [FileSink.start]
  final FileSinkStartBehavior behavior;

  FileSink({required this.filename, required this.behavior});

  /// Flushes all received [LogEntry] instances to the logfile
  @override
  Future<void> flush(final List<LogEntry> entries, final String loggerName,
      final DateTimeFMT fmt) async {
    final File logFile = File(filename);
    if (!await logFile.exists()) {
      await logFile.create(recursive: true);
    }

    final RandomAccessFile access = await logFile.open(mode: FileMode.append);
    await access.writeString(
        entries.map((e) => '${e.asString(loggerName, fmt)}\n').join());
    await access.close();
  }

  /// Synchronously flushes all received [LogEntry] instances to the logfile
  @override
  void flushSync(final List<LogEntry> entries, final String loggerName,
      final DateTimeFMT fmt) async {
    final File logFile = File(filename);
    if (!logFile.existsSync()) {
      logFile.createSync(recursive: true);
    }

    logFile.writeAsStringSync(
        entries.map((e) => '${e.asString(loggerName, fmt)}\n').join(),
        mode: FileMode.append,
        flush: true);
  }

  /// Depending on [behavior] it clears the logfile if it already exists
  @override
  void start() {
    if (behavior == FileSinkStartBehavior.CLEAR) {
      final File logFile = File(filename);
      if (logFile.existsSync()) {
        logFile.deleteSync();
      }
    }
  }
}

/// A [LoggerSink] that logs to both the terminal and a file
class ConsoleAndFileSink extends LoggerSink {
  /// The file path of the log
  final String filename;

  /// Specifies whether the [ConsoleAndFileSink] should clear the file on [ConsoleAndFileSink.start]
  final FileSinkStartBehavior behavior;

  ConsoleAndFileSink({required this.filename, required this.behavior});

  /// Flushes all received [LogEntry] instances to the logfile and the terminal
  @override
  Future<void> flush(final List<LogEntry> entries, final String loggerName,
      final DateTimeFMT fmt) async {
    final File logFile = File(filename);
    if (!await logFile.exists()) {
      await logFile.create(recursive: true);
    }

    final String buf =
        entries.map((e) => '${e.asString(loggerName, fmt)}\n').join();
    print(buf);

    final RandomAccessFile access = await logFile.open(mode: FileMode.append);
    await access.writeString(buf);
    await access.close();
  }

  /// Synchronously flushes all received [LogEntry] instances to the logfile and the terminal
  @override
  void flushSync(final List<LogEntry> entries, final String loggerName,
      final DateTimeFMT fmt) async {
    final File logFile = File(filename);
    if (!logFile.existsSync()) {
      logFile.createSync(recursive: true);
    }

    logFile.writeAsStringSync(
        entries.map((e) => '${e.asString(loggerName, fmt)}\n').join(),
        mode: FileMode.append,
        flush: true);
  }

  /// Depending on [behavior] it clears the logfile if it already exists
  @override
  void start() {
    if (behavior == FileSinkStartBehavior.CLEAR) {
      final File logFile = File(filename);
      if (logFile.existsSync()) {
        logFile.deleteSync();
      }
    }
  }
}

/// A user implemented [LoggerSink] that eg. could be used to send the [LogEntry] representations to a remote logging server
class CustomSink extends LoggerSink {
  /// User defined startup behavior
  final void Function() startImpl;

  /// User defined flush behavior
  final Future<void> Function(List<LogEntry>, String, DateTimeFMT) flushImpl;

  /// User defined flush behavior
  final void Function(List<LogEntry>, String, DateTimeFMT) flushImplSync;

  CustomSink(
      {required this.startImpl,
      required this.flushImpl,
      required this.flushImplSync});

  /// Flushes all received [LogEntry] instances using the user supplied flush behavior
  @override
  Future<void> flush(final List<LogEntry> entries, final String loggerName,
      final DateTimeFMT fmt) async {
    flushImpl(entries, loggerName, fmt);
  }

  /// Flushes all received [LogEntry] instances using the user supplied synchronous flush behavior
  @override
  void flushSync(List<LogEntry> entries, String loggerName, DateTimeFMT fmt) {
    flushImplSync(entries, loggerName, fmt);
  }

  /// Runs the user supplied startup behavior
  @override
  void start() {
    startImpl();
  }
}
