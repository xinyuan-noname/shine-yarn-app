import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/routes.dart';
import 'package:shine/utils/file_utils.dart';

/// 处理由应用外部交给闪纺的文件。
///
/// 手机上把闪纺选为 PDF 的「打开方式」（或在文件管理器里「用闪纺打开」）时，
/// 系统会把文件通过 VIEW intent（Android）/ 文档打开回调（iOS）交给闪纺：
/// 原生侧先把文件复制到应用缓存目录，再通过 `shine/launch` 通道把本地路径
/// 送到这里，由应用内的 PDF 阅读器打开。
/// 原生侧实现见 android/app/src/main/kotlin/com/example/shine/MainActivity.kt
/// 与 ios/Runner/AppDelegate.swift。
class LaunchService {
  LaunchService._();

  /// 与原生侧约定的通道名，修改时需要同步 Android 与 iOS。
  static const MethodChannel _channel = MethodChannel('shine/launch');

  /// 界面还没准备好之前，先把待打开的文件排在这里。
  static final List<String> _pending = [];

  /// 还没能提示给用户的失败信息（原生侧读取文件失败时回传）。
  static final List<String> _pendingMessages = [];

  /// 启动导航（清理路由栈）结束前不能打开文件，否则会被清掉。
  static bool _ready = false;
  static bool _draining = false;

  /// 在 `main` 里尽早调用：处理启动参数、登记通道，并取回原生侧可能已经
  /// 收到的文件（此时 Dart 还没准备好接收推送）。
  static void init(List<String> arguments) {
    for (final argument in arguments) {
      _enqueue(argument);
    }
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'openFile') {
        final arguments = call.arguments;
        if (arguments is String) {
          _enqueue(arguments);
        }
      } else if (call.method == 'openFailed') {
        final arguments = call.arguments;
        _pendingMessages.add(
          arguments is String ? arguments : '无法打开该文件',
        );
        unawaited(_drain());
      }
      return null;
    });
    unawaited(_pullInitialFiles());
  }

  /// 是否有外部送来、还没打开的文档。
  ///
  /// 启动时用它决定要不要给「等服务就绪」设个上限：本地文档不需要联网。
  static bool get hasPendingFile => _pending.isNotEmpty;

  /// 在应用完成启动导航后调用，这时才有地方可以打开文档。
  static void markReady() {
    if (_ready) {
      return;
    }
    _ready = true;
    unawaited(_drain());
  }

  /// 主动向原生侧取回启动时收到的文件，同时告诉它之后可以直接推送。
  static Future<void> _pullInitialFiles() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    try {
      final files = await _channel.invokeMethod<List<Object?>>(
        'getInitialFiles',
      );
      for (final file in files ?? const <Object?>[]) {
        if (file is String) {
          _enqueue(file);
        }
      }
    } on MissingPluginException {
      // 原生侧没实现该调用时忽略即可，推送方式依然可用。
    } on PlatformException {
      // 取回失败不影响后续打开。
    }
  }

  static void _enqueue(String argument) {
    final path = resolveFilePath(argument);
    if (path == null || _pending.contains(path)) {
      return;
    }
    _pending.add(path);
    unawaited(_drain());
  }

  static Future<void> _drain() async {
    if (!_ready || _draining) {
      return;
    }
    _draining = true;
    try {
      while (_pendingMessages.isNotEmpty || _pending.isNotEmpty) {
        if (globalNavigatorKey.currentState == null) {
          return;
        }
        if (_pendingMessages.isNotEmpty) {
          await showToast(msg: _pendingMessages.removeAt(0));
          continue;
        }
        await _open(_pending.removeAt(0));
      }
    } finally {
      _draining = false;
    }
  }

  static Future<void> _open(String path) async {
    if (isPdf(path)) {
      // 不等待页面关闭，否则同时打开的第二个文档会一直排队。
      unawaited(gotoViewPdfFile(path));
    } else if (isImageFile(path)) {
      unawaited(gotoViewImageFile(path));
    } else {
      await showToast(msg: '暂不支持打开 ${path.split(Platform.pathSeparator).last}');
      return;
    }
    // 留一帧给上一个页面入栈，避免同一帧里连续压入多个路由。
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// 按包名启动已安装的应用（Android）。
  ///
  /// 事项表里点「学习通」标签时用它唤起学习通：比猜 URL Scheme 可靠，
  /// 应用未安装时返回 false，由调用方退回到网页版。
  static Future<bool> openAppByPackage(String packageName) async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('openApp', packageName);
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// 把一个启动参数/原生回传值解析成绝对文件路径。
  ///
  /// 不是文件（例如引擎参数）或文件不存在时返回 null。
  static String? resolveFilePath(String argument) {
    var value = argument.trim();
    if (value.isEmpty || value.startsWith('-')) {
      return null;
    }
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }
    if (value.toLowerCase().startsWith('file:')) {
      try {
        value = Uri.parse(value).toFilePath();
      } catch (_) {
        return null;
      }
    }
    final file = File(value);
    if (!file.existsSync()) {
      return null;
    }
    return file.absolute.path;
  }
}
