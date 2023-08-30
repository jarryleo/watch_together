import 'package:logger/logger.dart';

import 'log_printer.dart';

class QLog {
  static const tag = 'QLOG';

  QLog._();

  static final CPrinter _printer =
      CPrinter(colors: true, printEmojis: false, printTime: true);
  static final Logger _logger = Logger(
    printer: PrettyPrinter(),
    level: Level.trace,
  );


  static CPrinter get printer => _printer;

  static void v(dynamic message,
      {String tag = QLog.tag,
      dynamic error,
      StackTrace? stackTrace,
      int? methodCount}) {
    _printer.setTag(tag);
    _printer.setDynamicMethodCount(methodCount);
    _logger.i(message ?? "null",error: error, stackTrace: stackTrace);
  }

  /// [message] 日志msg
  /// [tag]
  /// [error]
  /// [stackTrace]
  /// [methodCount] 日志堆栈层级数量，默认2
  static void d(dynamic message,
      {String tag = QLog.tag,
      dynamic error,
      StackTrace? stackTrace,
      int? methodCount}) {
    _printer.setTag(tag);
    _printer.setDynamicMethodCount(methodCount);
    _logger.d(message ?? "null",error: error, stackTrace: stackTrace);
  }

  static void i(dynamic message,
      {String tag = QLog.tag,
      dynamic error,
      StackTrace? stackTrace,
      int? methodCount}) {
    _printer.setTag(tag);
    _printer.setDynamicMethodCount(methodCount);
    _logger.i(message ?? "null", error: error, stackTrace: stackTrace);
  }

  static void w(dynamic message,
      {String tag = QLog.tag,
      dynamic error,
      StackTrace? stackTrace,
      int? methodCount}) {
    _printer.setTag(tag);
    _printer.setDynamicMethodCount(methodCount);
    _logger.w(message ?? "null", error: error, stackTrace: stackTrace);
  }

  static void e(dynamic message,
      {String tag = QLog.tag,
      dynamic error,
      StackTrace? stackTrace,
      int? methodCount}) {
    _printer.setTag(tag);
    _printer.setDynamicMethodCount(methodCount);
    _logger.e(message ?? "null", error: error, stackTrace: stackTrace);
  }

  static close() {
    _logger.close();
  }
}
