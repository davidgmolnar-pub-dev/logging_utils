import 'package:logging_utils/logging_utils.dart';

void main() {
  logging.setLoggerSinkLevel(LogLevel.INFO);
  logging.setDateTimeFMT(DateTimeFMT.TIME);
  logging.start();
  logging.info("info");
  logging.critical("critical");
  logging.stop();
}
