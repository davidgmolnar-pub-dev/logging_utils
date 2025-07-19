
import 'package:logging_utils/logging_utils.dart';

// TODO date fmt

void main() {
  logging.setLoggerSinkLevel(LogLevel.INFO);
  logging.start();
  logging.info("Asd");
  logging.critical("lol");
  logging.stop();
}
