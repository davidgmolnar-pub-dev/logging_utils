import 'dart:io';

import 'package:logging_utils/src/log_entry.dart';

enum FileSinkStartBehavior{
  // ignore: constant_identifier_names
  CLEAR,
  // ignore: constant_identifier_names
  KEEP
}

abstract class LoggerSink{
  Future<void> flush(final List<LogEntry> entries, final String loggerName);
  void start();
}

class ConsoleSink extends LoggerSink{
  @override
  Future<void> flush(final List<LogEntry> entries, final String loggerName) async {
    print(entries.map((e) => e.asString(loggerName)).join("\n"));
  }

  @override
  void start() {}
}

class FileSink extends LoggerSink{
  final String filename;
  final FileSinkStartBehavior behavior;

  FileSink({required this.filename, required this.behavior});

  @override
  Future<void> flush(final List<LogEntry> entries, final String loggerName) async {
    final File logFile = File(filename);
    if(!await logFile.exists()){
      await logFile.create(recursive: true);
    }

    final RandomAccessFile access = await logFile.open(mode: FileMode.append);
    await access.writeString(
      entries.map((e) => e.asString(loggerName)).join("\n")
    );
    await access.close();
  }

  @override
  void start() {
    if(behavior == FileSinkStartBehavior.CLEAR){
      final File logFile = File(filename);
      if(logFile.existsSync()){
        logFile.deleteSync();
      }
    }
  }
}

class ConsoleAndFileSink extends LoggerSink{
  final String filename;
  final FileSinkStartBehavior behavior;

  ConsoleAndFileSink({required this.filename, required this.behavior});
  
  @override
  Future<void> flush(final List<LogEntry> entries, final String loggerName) async {
    final File logFile = File(filename);
    if(!await logFile.exists()){
      await logFile.create(recursive: true);
    }

    final String buf = entries.map((e) => e.asString(loggerName)).join("\n");
    print(buf);

    final RandomAccessFile access = await logFile.open(mode: FileMode.append);
    await access.writeString(buf);
    await access.close();
  }

  @override
  void start() {
    if(behavior == FileSinkStartBehavior.CLEAR){
      final File logFile = File(filename);
      if(logFile.existsSync()){
        logFile.deleteSync();
      }
    }
  }
}

class CustomSink extends LoggerSink{
  final void Function() startImpl;
  final void Function(List<LogEntry>, String) flushImpl;

  CustomSink({required this.startImpl, required this.flushImpl});

  @override
  Future<void> flush(final List<LogEntry> entries, final String loggerName) async {
    flushImpl(entries, loggerName);
  }

  @override
  void start() {
    startImpl();
  }
}