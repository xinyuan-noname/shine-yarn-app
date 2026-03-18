import 'dart:async';

import 'package:flutter/widgets.dart';

/// 异步工具类
/// 
/// 提供基于 Flutter Widget 生命周期的异步操作工具
class AsyncUtils {
  /// 在下一帧渲染后执行异步操作
  /// 
  /// 这个方法是 [WidgetsBinding.instance.addPostFrameCallback] 的异步版本
  /// 适用于需要在 UI 构建完成后执行异步操作的场景
  /// 
  /// 使用示例:
  /// ```dart
  /// await AsyncUtils.postFrame(() async {
  ///   // 在这里执行异步操作
  ///   await someAsyncOperation();
  /// });
  /// ```
  /// 
  /// 注意：
  /// - 该方法必须在 Widget 上下文中调用（即有可用的 BuildContext）
  /// - 回调函数应该是异步的（返回 Future）
  /// - 会等待回调中的异步操作完成后再继续
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

  /// 在下一帧渲染后执行同步操作
  /// 
  /// 这是 [WidgetsBinding.instance.addPostFrameCallback] 的直接封装
  /// 适用于需要在 UI 构建完成后执行同步操作但不需要等待的场景
  /// 
  /// 使用示例:
  /// ```dart
  /// AsyncUtils.postFrameSync(() {
  ///   // 在这里执行同步操作
  ///   updateUI();
  /// });
  /// ```
  static void postFrameSync(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  /// 延迟执行异步操作
  /// 
  /// 结合 [Future.delayed] 和异步回调的工具方法
  /// 
  /// 参数:
  /// - [duration]: 延迟时间
  /// - [callback]: 异步回调函数
  /// 
  /// 使用示例:
  /// ```dart
  /// await AsyncUtils.delayed(Duration(seconds: 1), () async {
  ///   await someAsyncOperation();
  /// });
  /// ```
  static Future<void> delayed(
    Duration duration,
    Future<void> Function() callback,
  ) async {
    await Future.delayed(duration);
    await callback();
  }
}
