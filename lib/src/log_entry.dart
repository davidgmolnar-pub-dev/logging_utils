enum LogLevel{
  // ignore: constant_identifier_names
  INFO,
  // ignore: constant_identifier_names
  WARNING,
  // ignore: constant_identifier_names
  ERROR,
  // ignore: constant_identifier_names
  CRITICAL
}

class LogEntry{
  final String message;
  final LogLevel level;
  final DateTime timeStamp;

  const LogEntry(this.message, this.level, this.timeStamp);

  static LogEntry info(final String message){
    return LogEntry(message, LogLevel.INFO, DateTime.now());
  }

  static LogEntry warning(final String message){
    return LogEntry(message, LogLevel.WARNING, DateTime.now());
  }

  static LogEntry error(final String message){
    return LogEntry(message, LogLevel.ERROR, DateTime.now());
  }

  static LogEntry critical(final String message){
    return LogEntry(message, LogLevel.CRITICAL, DateTime.now());
  }

  String asString(final String loggerName) => "[$timeStamp] [$loggerName - ${level.name.toUpperCase()}] $message";
}