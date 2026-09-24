import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shine/cache/user_cache.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/download_progress_dialog.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/config/app_config.dart';
import 'package:shine/models/to_do_item_data.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api_admin.dart';
import 'package:shine/services/api_message.dart';
import 'package:shine/services/api_schedule.dart';
import 'package:shine/services/api_semesters.dart';
import 'package:shine/services/api_subjects.dart';
import 'package:shine/services/api_task.dart';
import 'package:shine/services/api_task_upload.dart';
import 'package:shine/services/api_update.dart';
import 'package:shine/services/notification.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_auth.dart';
import 'package:shine/services/api_group.dart';
import 'package:shine/services/api_profiles.dart';
import 'package:shine/services/event.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/storage/semester_storage.dart';
import 'package:shine/storage/subject_storage.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/storage/to_do_storage.dart';
import 'package:shine/models/course_data.dart';
import 'package:shine/services/download.dart';
import 'package:shine/utils/message_utils.dart';
import 'package:shine/utils/permission_utils.dart';
import 'package:shine/utils/upload_utils.dart';
import 'package:shine/utils/uri_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Worker {
  static Timer? _refreshTimer;
  static Timer? _urlTimer;
  static StreamSubscription<MessageEvent>? _badgeSubscription;
  static bool _elevate = false;
  static _afterRefresh() async {
    if (_elevate) {
      final result = await ApiAdmin.elevate();
      if (result is String) {
        _elevate = false;
        showToast(msg: "$result, 请稍后再试");
      } else {
        showToast(msg: "你的权限已成功提升至管理员");
      }
    }
  }

  static scheduleRefresh(Duration? duration) {
    const defaultDuration = Duration(minutes: 14, seconds: 30);
    _refreshTimer?.cancel();
    duration ??= defaultDuration;
    _refreshTimer = Timer(duration, () async {
      if (!ApiService.isOk) {
        Worker.scheduleRefreshNow();
        return;
      }
      await ApiAuth.refresh();
      _afterRefresh();
      Worker.scheduleRefresh(defaultDuration);
    });
  }

  static scheduleRefreshNow() {
    Worker.scheduleRefresh(Duration(milliseconds: 50));
  }

  static stopRefresh() {
    _refreshTimer?.cancel();
  }

  static scheduleElevate() {
    _elevate = true;
  }

  static scheduleElevateNow() {
    _elevate = true;
    Worker.scheduleRefreshNow();
  }

  static scheduleUrl(Duration? duration) {
    const defaultDuration = Duration(seconds: 3);
    _urlTimer?.cancel();
    duration ??= defaultDuration;
    _urlTimer = Timer(duration, () async {
      try {
        final url = await ApiService.getBaseUrl();
        if (url != ApiService.url) {
          ApiService.setBaseUrl(url);
        }
        Worker.scheduleUrl(defaultDuration);
        ApiService.closeOfflineMode();
      } on DioException catch (e) {
        showToast(msg: "服务未就绪，以离线模式进入");
        if (!AppConfig.isProduction) {
          showToast(msg: "错误原因：$e");
        }
        ApiService.openOfflineMode();
      } catch (e) {
        showToast(msg: "服务未就绪，以离线模式进入");
        if (!AppConfig.isProduction) {
          showToast(msg: "错误原因：$e");
        }
        ApiService.openOfflineMode();
      }
    });
  }

  static scheduleUrlNow() {
    Worker.scheduleUrl(Duration(milliseconds: 50));
  }

  static syncMyProfile() async {
    final result = await ApiProfiles.getMyProfile();
    if (result is Map) {
      final String? id = result["id"];
      final String? gender = result["gender"];
      final String? username = result["username"];
      final bool? passwordRequired = result["passwordRequired"];
      final String? major = result["major"];
      final String? $class = result["class"];
      final String? academy = result["academy"];
      if (id is String) {
        await ProfileStorage.saveId(id);
      }
      if (gender is String) {
        await ProfileStorage.saveGender(gender);
      }
      if (gender == null) {
        await ProfileStorage.delGender();
      }
      if (username is String) {
        await ProfileStorage.saveName(username);
      }
      if (passwordRequired is bool) {
        await ProfileStorage.savePasswordRequired(passwordRequired);
      }
      if (major is String) {
        await ProfileStorage.saveMajor(major);
      }
      if ($class is String) {
        await ProfileStorage.saveClass($class);
      }
      if (academy is String) {
        await ProfileStorage.saveAcademy(academy);
      }
    }
    if (result is String) showToast(msg: result);
  }

  static syncAllUser() async {
    final result = await ApiProfiles.getUserInfo();
    if (result is List) await ProfileStorage.saveUserList(result);
    if (result is String) showToast(msg: result);
  }

  static syncMyData() async {
    await Worker.syncMyProfile();
  }

  /// 获取指定分组的成员列表，优先使用本地缓存，缓存不存在时向服务器获取
  static Future<List<Map<String, dynamic>>> getUserListByGroup(
    GroupStorageKey nameKeyEnum, {
    bool force = false,
  }) async {
    List<Map<String, dynamic>>? list;
    if (!force) {
      list = await GroupStorage.getGroupUserList(nameKeyEnum);
    }
    if (list == null) {
      final result = await ApiGroup.getGlobalGroupData(nameKeyEnum);
      if (result is! List) return [];
      list = result.whereType<Map<String, dynamic>>().toList();
      await GroupStorage.saveGroupUserList(nameKeyEnum, list);
    }
    if (nameKeyEnum == GroupStorageKey.entire) {
      UserCache.setFromGroupDataList(list);
    }
    return list;
  }

  static syncGlobalGroup({bool force = false}) async {
    final list = GroupStorageKey.values;
    for (final nameKeyEnum in list) {
      await Worker.getUserListByGroup(nameKeyEnum, force: force);
    }
  }

  static syncSemester() async {
    final result = await ApiSemesters.getCurrentSemester();
    if (result.message is String) return;
    final phaseList = result.phaseList;
    final semesterName = result.semesterName;
    final startedAt = result.startedAt;
    if (phaseList == null || semesterName == null || startedAt == null) {
      return;
    }
    final name = await SemesterStorage.getCurrentSemesterName();
    if (name != null && name == semesterName) return;
    await Future.wait([
      SemesterStorage.setCurrentSemesterName(semesterName),
      SemesterStorage.setCurrentSemesterPhaseList(phaseList),
      SemesterStorage.setCurrentSemesterStartedAt(startedAt),
    ]);
  }

  static Future<List<CourseData>?> syncSubjects() async {
    final subjectInfoResult = await ApiSubjects.getCurrentSubjects();
    if (subjectInfoResult is List) {
      final list = subjectInfoResult.whereType<Map<String, dynamic>>().map((e) {
        return CourseData.fromJson(e);
      }).toList();
      SubjectStorage.setCurrentSubjectInfo(jsonEncode(subjectInfoResult));
      return list;
    }
    return null;
  }

  static Future<List<ScheduleData>?> syncSchedule() async {
    final scheduleResult = await ApiSchedule.getCurrentSchedule();
    if (scheduleResult is List) {
      final list = scheduleResult.whereType<Map<String, dynamic>>().map((e) {
        return ScheduleData.fromJson(e);
      }).toList();
      SubjectStorage.setCurrentScheduleInfo(jsonEncode(scheduleResult));
      return list;
    }
    return null;
  }

  static Future<List<TaskStorageData>?> syncTask() async {
    final uploadTaskResult = await ApiTask.getAllTasks();
    if (uploadTaskResult is List) {
      final List<TaskStorageData> result = [];
      final uploadTasks = uploadTaskResult.reversed
          .whereType<Map<String, dynamic>>();
      for (final taskInfo in uploadTasks) {
        switch (taskInfo["taskType"]) {
          case "upload":
            result.add(UploadTaskStorageData.fromMap(taskInfo));
          case "draw":
            result.add(DrawTaskStorageData.fromMap(taskInfo));
          case "vote":
            result.add(VoteTaskStorageData.fromMap(taskInfo));
        }
      }
      return result;
    }
    return null;
  }

  static Future<List<TaskStorageData>?> syncTaskNotice() async {
    final taskNoticeResult = await ApiMessage.getAllNotice();
    if (taskNoticeResult is List) {
      final List<TaskStorageData> result = [];
      final taskNoticeList = taskNoticeResult.reversed
          .whereType<Map<String, dynamic>>();
      for (final noticeInfo in taskNoticeList) {
        switch (noticeInfo["taskType"]) {
          case "upload":
            result.add(UploadTaskStorageData.fromMap(noticeInfo));
        }
      }
      return result;
    }
    return null;
  }

  static Future<List<UploadData>?> syncMyUploads() async {
    final myUploadsResult = await ApiTaskUpload.getMyUploads();
    if (myUploadsResult is List) {
      final myUploadsList = myUploadsResult.whereType<Map<String, dynamic>>();
      return myUploadsList.map((e) => UploadData.fromMap(e)).toList();
    }
    return null;
  }

  static Future<List<UploadData>?> syncUploadsByTaskId(int taskId) async {
    final uploadsResult = await ApiTaskUpload.getUploadsByTaskId(taskId);
    if (uploadsResult is List) {
      final uploadsList = uploadsResult.whereType<Map<String, dynamic>>();
      return uploadsList.map((e) => UploadData.fromMap(e)).toList();
    }
    return null;
  }

  static Future<List<ToDoItemData>?> syncToDoList() async {
    final result = await ApiMessage.getPublicToDoList();
    if (result is List) {
      final list = result.whereType<Map<String, dynamic>>();
      final toDoList = list.map((e) => ToDoItemData.fromMap(e)).toList();
      // 同步成功后整体覆盖本地缓存，断网时事项表也能显示上次的内容
      await ToDoStorage.saveToDoList(toDoList);
      return toDoList;
    }
    return null;
  }

  static startTaskWebSocket() {
    WsTask.start();
  }

  static closeTaskWebSocket() {
    WsTask.close();
  }

  static startSystemNotification() {
    Worker.startMessageNotification();
  }

  static startMessageNotification() {
    if (_badgeSubscription != null) return;
    _badgeSubscription = EventBus.stream.listen((event) async {
      final count = await countMessageBadge();
      await NotificationService.showNotification(
        id: 1000,
        title: '你有$count条新消息',
        body: '来自${event.sourceUser}等',
        badgeCount: count,
      );
    });
  }

  /// 下载文件。
  ///
  /// [onProgress] 是 0-100 的进度；[onDownloaded] 拿到文件的真实路径
  /// （打开安装包 / 查看文件都要用真实路径，自己拼 baseDirectory 会拼错）；
  /// [fallbackToOpenUrl] 表示下载失败时改用浏览器下载；
  /// [baseDirectory] 决定文件落在哪个目录 —— 系统会清理缓存目录，
  /// 所以安装包这类要留着的东西用 [BaseDirectory.applicationSupport]。
  static Future<String?> startDownload({
    required String url,
    required String filename,
    bool fallbackToOpenUrl = false,
    BaseDirectory baseDirectory = BaseDirectory.temporary,
    void Function(int progress)? onProgress,
    void Function(String filePath)? onDownloaded,
    VoidCallback? onFailed,
  }) async {
    final target = ensureUrl(url);
    var failedHandled = false;
    void handleFailure() {
      if (failedHandled) return;
      failedHandled = true;
      onFailed?.call();
      if (!fallbackToOpenUrl) return;
      // 兜底：直接用浏览器下载同一个地址，免得用户卡在失败提示上
      showToast(msg: "下载失败，正在跳转至下载链接").then((_) {
        launchUrl(
          Uri.parse(target),
          mode: LaunchMode.externalApplication,
          browserConfiguration: BrowserConfiguration(showTitle: true),
        );
      });
    }

    try {
      final downloader = DownloadUtils();
      await downloader.init();
      return await downloader.startDownload(
        url: target,
        // 只有自家服务端的地址才带鉴权头：更新包走的是 GitHub 代理，
        // 没必要把自己的访问令牌交给第三方
        headers: _isOwnServerUrl(target)
            ? ApiService.headers.cast<String, String>()
            : null,
        filename: filename,
        baseDirectory: baseDirectory,
        onProgress: (taskId, progress) => onProgress?.call(progress),
        onStatusChanged: (taskId, status) {
          switch (status) {
            case TaskStatus.complete:
              showToast(
                msg: "“$filename”下载完成",
                duration: Duration(seconds: 4),
              );
              break;
            case TaskStatus.waitingToRetry:
              showToast(msg: "“$filename”下载中断，正在自动重试");
              break;
            case TaskStatus.notFound:
            case TaskStatus.failed:
              showToast(msg: "“$filename”下载失败，请重试下载");
              handleFailure();
              break;
            case TaskStatus.canceled:
              showToast(msg: "“$filename”下载已取消");
              break;
            case TaskStatus.paused:
              showToast(msg: "“$filename”下载暂停");
              break;
            default:
              break;
          }
        },
        onDone: (taskId, filePath) {
          if (filePath != null) {
            onDownloaded?.call(filePath);
            return;
          }
          // 文件没落盘（被系统清掉、路径解析失败）时不能当成成功，
          // 否则下一步只会拿到一个「文件不存在」
          showToast(msg: "“$filename”下载完成了，但找不到文件");
          handleFailure();
        },
      );
    } catch (e) {
      handleFailure();
    }
    return null;
  }

  /// 地址是否指向自家服务端（用于决定要不要带鉴权头）
  static bool _isOwnServerUrl(String url) {
    final base = ApiService.url;
    // 服务端地址还没确定时宁可少带一个头：
    // 把访问令牌发给第三方，比这次下载失败严重得多
    if (base.isEmpty) return false;
    return url.startsWith(base);
  }

  /// 打开下载好的安装包：Android 交给系统安装器，Windows 直接运行安装程序
  static Future<void> openUpdatePackage(String filePath) async {
    var result = await OpenFile.open(filePath);
    // Android 8 起安装 apk 需要「允许安装未知应用」，插件只会返回权限错误；
    // 这里直接把用户带到系统开关，授权后自动重试一次
    if (result.type == ResultType.permissionDenied &&
        !kIsWeb &&
        Platform.isAndroid) {
      final granted = await PermissionUtils.requestInstallPermission();
      if (!granted) {
        showToast(msg: "需要打开「允许安装未知应用」才能完成更新");
        return;
      }
      result = await OpenFile.open(filePath);
    }
    if (result.type == ResultType.done) return;
    showToast(msg: "打开安装包失败：${result.message}");
  }

  /// 检查更新：发现新版本时提示用户，并在应用内下载安装包
  static Future<void> checkAndUpdate(BuildContext? context) async {
    if (kIsWeb) return;
    // 只有 Android（apk）和 Windows（setup.exe）有对应安装包，
    // 其它平台（iOS / macOS / Linux）没有可更新的包，不打扰用户
    if (!Platform.isAndroid && !Platform.isWindows) return;
    if (!AppConfig.isProduction) return;
    final check = await ApiUpdate.checkLatest();
    final release = check.release;
    if (release == null) return;
    final isWindows = ApiUpdate.isWindowsPlatform;
    final assetName = release.assetNameFor(isWindows: isWindows);
    final fileUrl = ApiUpdate.getUpdateUrl(assetName);
    // 当前平台没有发布包（例如只发了 apk 没发 setup）时不用打扰用户
    if (assetName.isEmpty || fileUrl.isEmpty) return;
    final packageInfo = await PackageInfo.fromPlatform();
    final localVersion = ApiUpdate.buildLocalVersion(
      packageInfo.version,
      packageInfo.buildNumber,
    );
    final remoteVersion = release.versionFor(isWindows: isWindows);
    if (!isNewerVersion(remoteVersion, localVersion)) return;
    final dialogContext = context != null && context.mounted
        ? context
        : globalNavigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted) return;
    bool confirm;
    if (release.forceUpdate) {
      confirm = await showConfirmDialog(
        context: dialogContext,
        title: "检测到新版本，本次更新是必须的！本次进入将以严格离线模式进入！",
        content: "本次更新内容：${release.displayInfo}",
      );
      ApiService.openStrictOfflineMode();
      showToast(msg: "进入严格离线模式");
    } else {
      confirm = await showConfirmDialog(
        context: dialogContext,
        title: "检测到新版本，请立即更新！",
        content:
            "版本 $localVersion → $remoteVersion\n本次更新内容：${release.displayInfo}",
      );
    }
    if (!confirm) return;
    if (!dialogContext.mounted) return;
    await downloadUpdatePackage(context: dialogContext, release: release);
  }

  /// 下载更新包，下载完成后直接打开安装包。
  ///
  /// 「检查更新」和「我」页面的跳转更新共用这一段：
  /// 下载前先弹进度弹窗（可取消），结束后不管成功失败都会把弹窗关掉。
  static Future<void> downloadUpdatePackage({
    required BuildContext context,
    required AppReleaseInfo release,
  }) async {
    final isWindows = ApiUpdate.isWindowsPlatform;
    final assetName = release.assetNameFor(isWindows: isWindows);
    final fileUrl = ApiUpdate.getUpdateUrl(assetName);
    if (assetName.isEmpty || fileUrl.isEmpty) {
      showToast(msg: "当前平台还没有可用的更新包");
      return;
    }
    final remoteVersion = release.versionFor(isWindows: isWindows);
    final progress = ValueNotifier<int>(-1);
    final done = Completer<String?>();
    void complete(String? filePath) {
      if (done.isCompleted) return;
      done.complete(filePath);
    }

    // 文件名用远端安装包名（带版本号）：既方便用户识别，
    // 也避免和上一个版本残留的半包混在一起
    final closeDialog = showDownloadProgressDialog(
      context: context,
      progress: progress,
      title: "正在下载新版本 $remoteVersion",
      description: "下载完成后会直接打开安装包，也可以先取消稍后再说",
      onCancel: () {
        // 取消后下载不会再回调，这里自己收尾，避免弹窗和等待一直悬着
        DownloadUtils().cancelAllDownloads();
        complete(null);
      },
    );

    await startDownload(
      url: fileUrl,
      filename: assetName,
      baseDirectory: BaseDirectory.applicationSupport,
      fallbackToOpenUrl: true,
      onProgress: (percent) => progress.value = percent,
      onDownloaded: (filePath) => complete(filePath),
      onFailed: () => complete(null),
    );
    // startDownload 要等下载结束才返回，此时成功 / 失败的回调都已经跑过；
    // 还没结束说明是被取消或异常收场，这里自己收尾，别让弹窗一直挂着
    complete(null);
    final filePath = await done.future;
    closeDialog();
    progress.dispose();
    if (filePath == null) return;
    showToast(msg: "下载完成，正在打开安装包");
    await openUpdatePackage(filePath);
  }

  static void dispose() {
    _refreshTimer?.cancel();
    _urlTimer?.cancel();
    _badgeSubscription?.cancel();
    Worker.closeTaskWebSocket();
  }
}
