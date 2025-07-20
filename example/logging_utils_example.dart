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
}
