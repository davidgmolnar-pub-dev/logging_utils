import 'dart:async';
import 'dart:isolate';

import 'package:logging_utils/src/log_entry.dart';
import 'package:logging_utils/src/logger_sink.dart';

typedef Logger = AsyncLogger;

/// Root logger, preconfigured to log in the terminal
final Logger logging =
    Logger(loggerName: "ROOT", sink: ConsoleSink(), loggerCallback: null);

/// Logger base class
///
/// Based on assigned [LoggerSink] it can log in the terminal, to a file or to a remote through a network using [CustomSink].
/// The [Logger] can be listened to, using the provided loggerCallback. All [LogEntry] instances above sinkLevel are flushed to the given [LoggerSink].
/// Defaults: warning sinkLevel and DateTime formatting
abstract class _LoggerBase {
  bool _isActive = false;
  LoggerSink _sink;
  String _loggerName;
  void Function(LogEntry)? _loggerCallback;
  LogLevel _sinkLevel = LogLevel.WARNING;
  DateTimeFMT _fmt = DateTimeFMT.DATETIME;

  _LoggerBase(
      {required String loggerName,
      required LoggerSink sink,
      required void Function(LogEntry)? loggerCallback})
      : _loggerCallback = loggerCallback,
        _sink = sink,
        _loggerName = loggerName;

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
  void start();

  /// Deactivates the [Logger], all as of yet unflushed [LogEntry] instances are flushed by the time this future finalizes.
  Future<void> stop();

  void _sleep();

  void _wake();

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

  /// Adds a [LogEntry] instance
  void add(final LogEntry entry);

  /// Adds [LogEntry] instances in a batch
  void addAll(final List<LogEntry> entries);
}

/// AsyncLogger class
///
/// Based on assigned [LoggerSink] it can log in the terminal, to a file or to a remote through a network using [CustomSink].
/// The [Logger] can be listened to, using the provided loggerCallback. All [LogEntry] instances above sinkLevel are flushed in batches of flushInterval apart in an async manner.
/// Defaults: 1000 ms flushInterval, warning sinkLevel and DateTime formatting
class AsyncLogger extends _LoggerBase{
  Timer? _timer;
  int _flushInterval = 1000;
  List<LogEntry> _buffer = [];
  
  AsyncLogger({required super.loggerName, required super.sink, required super.loggerCallback});

  /// Modifies the interval with which the [LoggerSink] flushes [LogEntry] instances.
  void setFlushInterval(final int intervalMs) async {
    _sleep();
    _flushInterval = intervalMs;
    if (_isActive) {
      _wake();
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

  @override
  void _sleep() {
    _timer?.cancel();
  }

  @override
  void _wake() {
    if (_timer?.isActive ?? false) {
      return;
    }
    _timer =
        Timer.periodic(Duration(milliseconds: _flushInterval), ((timer) async {
      await _flush();
    }));
  }

  @override
  void start() {
    if (_isActive) {
      return;
    }

    _sink.start();

    _timer =
        Timer.periodic(Duration(milliseconds: _flushInterval), ((timer) async {
      await _flush();
    _isActive = true;
    }));
  }

  @override
  Future<void> stop() async {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    _timer?.cancel();
    await _flush();
  }

  @override
  void addAll(final List<LogEntry> entries) {
    _buffer.addAll(entries);
    if (entries.isNotEmpty) {
      _wake();
    }
    if (_loggerCallback != null) {
      entries.forEach(_loggerCallback!);
    }
  }

  @override
  void add(final LogEntry entry) {
    _buffer.add(entry);
    _wake();
    if (_loggerCallback != null) {
      _loggerCallback!(entry);
    }
  }
}

class _LoggerWorker{
  Isolate? _handle;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  Completer<void>? _isolateReady;
  Completer<void>? _shutdownReady;

  _LoggerWorker();

  Future<void> start(final LoggerSink sink) async{
    if(_handle != null){
      return;
    }

    _isolateReady = Completer.sync();
    _shutdownReady = Completer.sync();
    _receivePort = ReceivePort();
    _receivePort!.listen(_isolateListener);

    try{
      _handle = await Isolate.spawn(_isolateMain, _receivePort!.sendPort);
    }
    catch(ex){
      _receivePort!.close();
      _receivePort = null;
      _isolateReady = null;
      _shutdownReady = null;
      _handle = null;
      rethrow;
    }

    await _isolateReady!.future;
    _sendPort!.send(sink);
  }

  void _isolateListener(final dynamic message){
    if(message is SendPort){
      _sendPort = message;
      _isolateReady?.complete();
    }
    else if(message is bool && !message){
      _shutdownReady?.complete();
    }
  }

  static void _isolateMain(final SendPort port){
    final ReceivePort receivePort = ReceivePort();
    port.send(receivePort.sendPort);

    LoggerSink? sink;

    receivePort.listen((final dynamic message) async {
      if(message is LoggerSink){
        sink = message;
      }
      else if (message is List) {
        sink?.flush(message[0], message[1], message[2]);
      }
      else if(message is bool && !message){
        port.send(false);
        receivePort.close();
      }
    });
  }

  Future<void> stop() async {
    if(_handle == null){
      return;
    }

    _sendPort!.send(false);
    await _shutdownReady!.future;
    _handle!.kill(priority: 0);
    _handle = null;
    
    _receivePort?.close();
    
    _receivePort = null;
    _sendPort == null;
  }

  void flush(final List<LogEntry> entries, final String loggerName, final DateTimeFMT fmt){
    _sendPort!.send([entries, loggerName, fmt]);
  }
}

/// ThreadedLogger class
///
/// Based on assigned [LoggerSink] it can log in the terminal, to a file or to a remote through a network using [CustomSink].
/// The [Logger] can be listened to, using the provided loggerCallback. All [LogEntry] instances above sinkLevel are flushed immediately in an isolate.
/// Defaults: warning sinkLevel and DateTime formatting
class ThreadedLogger extends _LoggerBase{
  final _LoggerWorker _worker = _LoggerWorker();

  ThreadedLogger({required super.loggerName, required super.sink, required super.loggerCallback});

  @override
  Future<void> _sleep() async {
    await _worker.stop();
  }

  @override
  void _wake() {
    _worker.start(_sink);
  }

  @override
  Future<void> start() async {
    if (_isActive) {
      return;
    }

    await _worker.start(_sink);
    _isActive = true;
  }

  @override
  Future<void> stop() async {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    await _worker.stop();
  }  
  
  @override
  void addAll(final List<LogEntry> entries) {
    if (entries.isNotEmpty) {
      _wake();
    }
    if (_loggerCallback != null) {
      entries.forEach(_loggerCallback!);
    }
    _worker.flush(entries, _loggerName, _fmt);
  }

  @override
  void add(final LogEntry entry) {
    _wake();
    if (_loggerCallback != null) {
      _loggerCallback!(entry);
    }
    _worker.flush([entry], _loggerName, _fmt);
  }
}