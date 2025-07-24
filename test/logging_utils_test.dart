import 'package:logging_utils/logging_utils.dart';

void main() async {
  ThreadedLogger tlogger = ThreadedLogger(
      loggerName: "MAIN", sink: ConsoleSink(), loggerCallback: null);
  await tlogger.start();

  tlogger.debug("debug");
  tlogger.info("info");
  tlogger.warning("warning");
  tlogger.error("error");
  tlogger.critical("critical");
  await Future.delayed(Duration(seconds: 1));

  tlogger.setLoggerSink(
      FileSink(filename: "a.log", behavior: FileSinkStartBehavior.CLEAR));
  tlogger.setDateTimeFMT(DateTimeFMT.TS_US);
  tlogger.setLoggerName("CHILD");
  tlogger.setLoggerSinkLevel(LogLevel.ERROR);

  tlogger.debug("debug");
  tlogger.info("info");
  tlogger.warning("warning");
  tlogger.error("error");
  tlogger.critical("critical");
  await Future.delayed(Duration(seconds: 1));

  tlogger.setLoggerSink(ConsoleSink());
  tlogger.setDateTimeFMT(DateTimeFMT.TIME);
  tlogger.setLoggerName("PROC");
  tlogger.setLoggerSinkLevel(LogLevel.INFO);

  tlogger.debug("debug");
  tlogger.info("info");
  tlogger.warning("warning");
  tlogger.error("error");
  tlogger.critical("critical");
  await Future.delayed(Duration(seconds: 1));
  await tlogger.stop();
}
