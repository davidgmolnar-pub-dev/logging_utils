[![Pub](https://img.shields.io/pub/v/logging_utils.svg)](https://pub.dev/packages/logging_utils)

A package for logging with more extensive options than the built in logger.

## Features

- Modularized logging
- Predefined loggers to log to the terminal or a file
- Custom logger to send log messages to a remote logging server
- Timestamp formatting

## Usage

Simply using predefined logger:
```dart
logging.start();
...
logging.info("info");
logging.critical("critical");
...
await logging.stop()
```

Or using a user-configured logger:
```dart
final Logger logger = Logger(
    loggerName: "MAIN",
    sink: FileSink(filename: "log.txt", behavior: FileSinkStartBehavior.CLEAR),
    loggerCallback: null
);
logger.setFlushInterval(100);
logger.setDateTimeFMT(DateTimeFMT.DATE);
logger.setLoggerSinkLevel(LogLevel.ERROR);
logger.start();
// ...
logger.info("info");
logger.critical("critical");
// ...
await logger.stop();
```

Same available with a threaded logger:
```dart
ThreadedLogger tlogger = ThreadedLogger(loggerName: "MAIN", sink: ConsoleSink(), loggerCallback: null);
await tlogger.start();
// ...
tlogger.warning("warning");
tlogger.critical("critical");
// ...
tlogger.setLoggerSink(FileSink(filename: "a.log", behavior: FileSinkStartBehavior.CLEAR));
tlogger.setDateTimeFMT(DateTimeFMT.TS_US);
tlogger.setLoggerName("CHILD");
tlogger.setLoggerSinkLevel(LogLevel.ERROR);
// ...
tlogger.info("info");
tlogger.critical("critical");
// ...
await tlogger.stop();
```

On-the-fly reconfiguration possible for both the AsyncLogger and ThreadedLogger options.