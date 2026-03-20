import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:shine/components/toast.dart';

import 'permission_utils.dart';

typedef DownloadCallback = void Function(String taskId, TaskStatus status);

typedef DownloadProgressCallback = void Function(String taskId, int progress);

class DownloadTaskWrapper {
  final DownloadTask task;
  final String url;
  final String filename;

  DownloadTaskWrapper({
    required this.task,
    required this.url,
    required this.filename,
  });
}

class DownloadUtils {
  static final DownloadUtils _instance = DownloadUtils._internal();
  factory DownloadUtils() => _instance;
  DownloadUtils._internal();

  final FileDownloader _downloader = FileDownloader();

  final Map<String, DownloadTaskWrapper> _activeTasks = {};

  /// 下载进度缓存
  final Map<String, int> _progressCache = {};

  /// 初始化标志
  bool _isInitialized = false;

  /// 监听器订阅
  StreamSubscription? _updatesSubscription;

  /// 初始化下载器（可选，用于配置全局设置）
  /// 注意：只需调用一次，重复调用不会重复注册监听器
  Future<void> init() async {
    // 防止重复初始化
    if (_isInitialized) {
      print('DownloadUtils 已初始化，无需重复调用');
      return;
    }

    // 启动下载器以激活数据库并确保正确重启
    await _downloader.start();

    // 配置全局事件监听器
    _updatesSubscription = _downloader.updates.listen((update) {
      switch (update) {
        case TaskStatusUpdate():
          // 处理状态更新
          final taskId = update.task.taskId;
          final status = update.status;

          if (status == TaskStatus.complete ||
              status == TaskStatus.canceled ||
              status == TaskStatus.failed) {
            _activeTasks.remove(taskId);
            _progressCache.remove(taskId);
          }
          break;

        case TaskProgressUpdate():
          // 处理进度更新
          final taskId = update.task.taskId;
          final progress = (update.progress * 100).toInt();
          _progressCache[taskId] = progress;
          break;
      }
    });

    _isInitialized = true;
    print('DownloadUtils 初始化完成');
  }

  Future<bool> _checkPermission() async {
    return await PermissionUtils.ensureDownloadPermission();
  }

  /// 开始下载
  ///
  /// [url] 下载地址
  /// [filename] 文件名（可选，不提供则自动生成）
  /// [headers] 请求头（可选），如 {'Authorization': 'Bearer xxx'}
  /// [title] 通知标题
  /// [description] 通知描述
  /// [onStatusChanged] 状态变化回调
  /// [onProgress] 进度回调
  Future<String?> startDownload({
    required String url,
    String? filename,
    Map<String, String>? headers,
    String title = '正在下载...',
    String description = '请稍候',
    DownloadCallback? onStatusChanged,
    DownloadProgressCallback? onProgress,
  }) async {
    try {
      // 检查权限
      final hasPermission = await _checkPermission();
      if (!hasPermission) {
        showToast(msg: '需要存储权限以下载文件');
        return null;
      }

      // 生成文件名
      final actualFilename = filename ?? _generateFilename(url);

      // 创建下载任务
      final task = DownloadTask(
        url: url,
        filename: actualFilename,
        headers: headers, // 支持自定义请求头
        updates: Updates.statusAndProgress,
        allowPause: true,
      );

      // 开始下载
      _activeTasks[task.taskId] = DownloadTaskWrapper(
        task: task,
        url: url,
        filename: actualFilename,
      );

      await _downloader.download(
        task,
        onProgress: (progress) {
          final percent = (progress * 100).toInt();
          _progressCache[task.taskId] = percent;
          onProgress?.call(task.taskId, percent);
        },
        onStatus: (status) {
          onStatusChanged?.call(task.taskId, status);
        },
      );

      return task.taskId;
    } catch (e) {
      showToast(msg: '下载失败：${e.toString()}');
      return null;
    }
  }

  Future<List<String?>> batchDownload({
    required List<Map<String, String>> tasks,
    void Function(String taskId)? onTaskComplete,
    void Function(List<String?> results)? onAllComplete,
  }) async {
    final results = <String?>[];

    for (final task in tasks) {
      final taskId = await startDownload(
        url: task['url']!,
        filename: task['filename'],
        onStatusChanged: (taskId, status) {
          if (status == TaskStatus.complete) {
            onTaskComplete?.call(taskId);
          }
        },
      );
      results.add(taskId);

      // 避免同时下载太多任务
      if (tasks.length > 3) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    onAllComplete?.call(results);
    return results;
  }

  Future<bool> pauseDownload(String taskId) async {
    try {
      final wrapper = _activeTasks[taskId];
      if (wrapper == null) {
        return false;
      }
      await _downloader.pause(wrapper.task);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resumeDownload(String taskId) async {
    try {
      final wrapper = _activeTasks[taskId];
      if (wrapper == null) {
        return false;
      }
      await _downloader.resume(wrapper.task);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelDownload(String taskId) async {
    try {
      final result = await _downloader.cancelTaskWithId(taskId);
      _activeTasks.remove(taskId);
      _progressCache.remove(taskId);
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<void> cancelAllDownloads() async {
    await _downloader.cancelAll();
    _activeTasks.clear();
    _progressCache.clear();
  }

  int? getProgress(String taskId) {
    return _progressCache[taskId];
  }

  bool isActiveTask(String taskId) {
    return _activeTasks.containsKey(taskId);
  }

  /// 生成文件名
  String _generateFilename(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    if (pathSegments.isNotEmpty) {
      final name = pathSegments.last;
      if (name.contains('.')) {
        return name;
      }
    }

    // 如果无法从 URL 获取文件名，使用时间戳
    final extension = _extractExtension(url);
    return 'download_${DateTime.now().millisecondsSinceEpoch}.$extension';
  }

  /// 从 URL 提取文件扩展名
  String _extractExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    final dotIndex = path.lastIndexOf('.');

    if (dotIndex != -1 && dotIndex < path.length - 1) {
      return path.substring(dotIndex + 1).toLowerCase();
    }

    return 'file';
  }

  /// 清理资源
  void dispose() async {
    // 取消所有下载
    await cancelAllDownloads();

    // 取消监听器订阅
    await _updatesSubscription?.cancel();
    _updatesSubscription = null;

    // 清空缓存
    _activeTasks.clear();
    _progressCache.clear();

    // 重置初始化标志
    _isInitialized = false;

    print('DownloadUtils 资源已释放');
  }
}

class DownloadTaskInfo {
  final String taskId;
  final String url;
  final String filename;
  final TaskStatus status;
  final int progress;
  final DateTime createdAt;

  DownloadTaskInfo({
    required this.taskId,
    required this.url,
    required this.filename,
    required this.status,
    required this.progress,
    required this.createdAt,
  });

  factory DownloadTaskInfo.fromMap(Map<String, dynamic> map) {
    return DownloadTaskInfo(
      taskId: map['taskId'] as String,
      url: map['url'] as String,
      filename: map['filename'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.notFound,
      ),
      progress: map['progress'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'url': url,
      'filename': filename,
      'status': status.name,
      'progress': progress,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
