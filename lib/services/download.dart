import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:shine/components/toast.dart';

import '../utils/permission_utils.dart';

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

  final Map<String, int> _progressCache = {};

  bool _isInitialized = false;

  StreamSubscription? _updatesSubscription;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    _downloader.configureNotification(
      running: TaskNotification("正在下载", "正在下载文件..."),
      complete: TaskNotification("下载完成", "文件已保存，点击可跳转"),
      paused: TaskNotification("下载暂停", "点击可继续"),
      canceled: TaskNotification("下载取消", "下载已取消"),
      error: TaskNotification("下载失败", "请重新下载"),
      progressBar: true,
      tapOpensFile: true,
    );

    await _downloader.start();

    _updatesSubscription = _downloader.updates.listen((update) {
      switch (update) {
        case TaskStatusUpdate():
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
          final taskId = update.task.taskId;
          final progress = (update.progress * 100).toInt();
          _progressCache[taskId] = progress;
          break;
      }
    });

    _isInitialized = true;
  }

  Future<bool> _checkPermission() async {
    return await PermissionUtils.ensureDownloadPermission();
  }

  Future<String?> startDownload({
    required String url,
    required String filename,
    Map<String, String>? headers,
    String title = '正在下载...',
    String description = '请稍候',
    DownloadCallback? onStatusChanged,
    DownloadProgressCallback? onProgress,
  }) async {
    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) {
        showToast(msg: '需要存储权限以下载文件');
        return null;
      }

      final task = DownloadTask(
        url: url,
        filename: filename,
        headers: headers,
        updates: Updates.statusAndProgress,
        allowPause: true,
        baseDirectory: BaseDirectory.temporary,
      );

      _activeTasks[task.taskId] = DownloadTaskWrapper(
        task: task,
        url: url,
        filename: filename,
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
        filename: task['filename']!,
        onStatusChanged: (taskId, status) {
          if (status == TaskStatus.complete) {
            onTaskComplete?.call(taskId);
          }
        },
      );
      results.add(taskId);

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

  void dispose() async {
    await cancelAllDownloads();

    await _updatesSubscription?.cancel();
    _updatesSubscription = null;

    _activeTasks.clear();
    _progressCache.clear();

    _isInitialized = false;
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
