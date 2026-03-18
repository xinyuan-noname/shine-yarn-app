import 'dart:async';

import 'package:flutter/widgets.dart';

/// 异步工具类
/// 
/// 提供基于 Flutter Widget 生命周期的异步操作工具
class AsyncUtils {

  static Future<void> postFrame(Future<void> Function() callback) {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        callback().then((_) {
          completer.complete();
        }).catchError((error) {
          completer.completeError(error);
        });
      } catch (e) {
        completer.completeError(e);
      }
    });
    return completer.future;
  }

  static void postFrameSync(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  static Future<void> delayed(
    Duration duration,
    Future<void> Function() callback,
  ) async {
    await Future.delayed(duration);
    await callback();
  }
}
