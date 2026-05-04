import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// 轻量日志封装，统一替代 debugPrint / print。
///
/// 仅在 debug 模式输出，release 自动静默。
abstract final class Log {
  /// 普通调试信息。
  static void d(String message, {String tag = 'KineCue'}) {
    if (kDebugMode) {
      dev.log(message, name: tag);
    }
  }

  /// 警告信息。
  static void w(String message, {String tag = 'KineCue'}) {
    if (kDebugMode) {
      dev.log('[WARN] $message', name: tag);
    }
  }

  /// 错误信息，可附带异常和堆栈。
  static void e(
    String message, {
    String tag = 'KineCue',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      dev.log(
        '[ERROR] $message',
        name: tag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
