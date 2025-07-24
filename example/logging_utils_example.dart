import 'package:logging_utils/logging_utils.dart';

void main() async {
  // simply using predefined logger

  logging.setLoggerSinkLevel(LogLevel.INFO);
  logging.setDateTimeFMT(DateTimeFMT.TIME);
  logging.start();
  // ...
  logging.info("info");
  logging.critical("critical");
  // ...
  await logging.stop();

  // or using a user-configured logger

  final Logger logger = Logger(
      loggerName: "MAIN",
      sink:
          FileSink(filename: "log.txt", behavior: FileSinkStartBehavior.CLEAR),
      loggerCallback: null);
  logger.setFlushInterval(100);
  logger.setDateTimeFMT(DateTimeFMT.DATE);
  logger.setLoggerSinkLevel(LogLevel.ERROR);
  logger.start();
  // ...
  logger.info("info");
  logger.critical("critical");
  // ...
  await logger.stop();

  // same available with a threaded logger

  ThreadedLogger tlogger = ThreadedLogger(
      loggerName: "MAIN", sink: ConsoleSink(), loggerCallback: null);
  // note that starting a ThreadedLogger needs to be awaited
  await tlogger.start();
  // ...
  tlogger.warning("warning");
  tlogger.critical("critical");
  // ...
  tlogger.setLoggerSink(
      FileSink(filename: "a.log", behavior: FileSinkStartBehavior.CLEAR));
  tlogger.setDateTimeFMT(DateTimeFMT.TS_US);
  tlogger.setLoggerName("CHILD");
  tlogger.setLoggerSinkLevel(LogLevel.ERROR);
  // ...
  tlogger.info("info");
  tlogger.critical("critical");
  // ...
  await tlogger.stop();
}
