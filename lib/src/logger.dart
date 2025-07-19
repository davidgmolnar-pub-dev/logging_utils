import 'dart:async';

import 'package:logging_utils/src/log_entry.dart';
import 'package:logging_utils/src/logger_sink.dart';

Logger logging = Logger(loggerName: "ROOT", sink: ConsoleSink(), loggerCallback: null);

class Logger{
  List<LogEntry> _buffer = [];
  bool _isActive = false;
  Timer? _timer;
  LoggerSink _sink;
  String _loggerName;
  void Function(LogEntry)? _loggerCallback;
  int _flushInterval = 1000;
  LogLevel _sinkLevel = LogLevel.WARNING;

  Logger({required String loggerName, required LoggerSink sink, required void Function(LogEntry)? loggerCallback}) : _loggerCallback = loggerCallback, _sink = sink, _loggerName = loggerName;

  void setFlushInterval(final int intervalMs) async {
    _flushInterval = intervalMs;
    if(_isActive){
      await stop();
      start();
    }
  }

  void setLoggerSink(final LoggerSink sink) async {
    final bool wasActive = _isActive;
    if(_isActive){
      await stop();
    }
    _sink = sink;
    if(wasActive){
      start();
    }
  }

  void setLoggerName(final String loggerName) async {
    final bool wasActive = _isActive;
    if(_isActive){
      await stop();
    }
    _loggerName = loggerName;
    if(wasActive){
      start();
    }
  }

    void setLoggerSinkLevel(final LogLevel level) async {
    final bool wasActive = _isActive;
    if(_isActive){
      await stop();
    }
    _sinkLevel = level;
    if(wasActive){
      start();
    }
  }

  void setLoggerCallback(final void Function(LogEntry)? loggerCallback) async {
    final bool wasActive = _isActive;
    if(_isActive){
      await stop();
    }
    _loggerCallback = loggerCallback;
    if(wasActive){
      start();
    }
  }

  void start(){
    if(_isActive){
      return;
    }

    _sink.start();

    _isActive = true;
    _timer = Timer.periodic(Duration(milliseconds: _flushInterval), ((timer) async {
      await _flush();
    }));
  }

  Future<void> stop() async {
    if(!_isActive){
      return;
    }
    _isActive = false;
    _timer?.cancel();
    await _flush();
  }

  void _sleep(){
    _timer?.cancel();
  }

  void _wake(){
    if(_timer?.isActive ?? false){
      return;
    }
    _timer = Timer.periodic(Duration(milliseconds: _flushInterval), ((timer) async {
      await _flush();
    }));
  }

  void info(final String message){
    if(!_isActive){
      return;
    }
    add(LogEntry(message, LogLevel.INFO, DateTime.now()));
  }

  void warning(final String message){
    if(!_isActive){
      return;
    }
    add(LogEntry(message, LogLevel.WARNING, DateTime.now()));
  }

  void error(final String message){
    if(!_isActive){
      return;
    }
    add(LogEntry(message, LogLevel.ERROR, DateTime.now()));
  }

  void critical(final String message){
    if(!_isActive){
      return;
    }
    add(LogEntry(message, LogLevel.CRITICAL, DateTime.now()));
  }

  void addAll(final List<LogEntry> entries){
    _buffer.addAll(entries);
    if(entries.isNotEmpty){
      _wake();
    }
  }

  void add(final LogEntry entry){
    _buffer.add(entry);
    _wake();
    if(_loggerCallback != null){
      _loggerCallback!(entry);
    }
  }

  Future<void> _flush() async {
    if(_buffer.isEmpty){
      _sleep();
      return;
    }

    final List<LogEntry> copy = _buffer;
    await _sink.flush(copy.where((e) => e.level.index >= _sinkLevel.index).toList(), _loggerName);
    _buffer = _buffer.skip(copy.length).toList();
  }
}