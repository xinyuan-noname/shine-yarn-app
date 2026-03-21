import 'dart:async';
import 'dart:convert';

import 'package:background_downloader/background_downloader.dart';
import 'package:dio/dio.dart';
import 'package:shine/cache/user_cache.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/services/api_admin.dart';
import 'package:shine/services/api_message.dart';
import 'package:shine/services/api_schedule.dart';
import 'package:shine/services/api_semesters.dart';
import 'package:shine/services/api_subjects.dart';
import 'package:shine/services/api_task.dart';
import 'package:shine/services/api_task_upload.dart';
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
import 'package:shine/utils/course.dart';
import 'package:shine/utils/download_utils.dart';
import 'package:shine/utils/message.dart';
import 'package:shine/utils/upload_utils.dart';

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
          print("更换url为:$url");
          ApiService.setBaseUrl(url);
        }
        Worker.scheduleUrl(defaultDuration);
      } on DioException {
        showToast(msg: "服务未就绪，以离线模式进入");
        ApiService.openOfflineMode();
      } catch (e) {
        showToast(msg: "服务未就绪，以离线模式进入");
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

  static syncGlobalGroup({bool force = false}) async {
    final list = GroupStorageKey.values;
    for (final nameKeyEnum in list) {
      if (!force) {
        final storage = await GroupStorage.getGroupUserList(nameKeyEnum);
        if (storage is List<Map<String, dynamic>>) {
          if (nameKeyEnum == GroupStorageKey.entire) {
            UserCache.setFromGroupDataList(storage);
          }
          continue;
        }
      }
      final result = await ApiGroup.getGlobalGroupData(nameKeyEnum);
      if (result is List) {
        await GroupStorage.saveGroupUserList(nameKeyEnum, result);
      }
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

  static startDownload({required String url, required String filename}) async {
    final downloader = DownloadUtils();
    await downloader.init();
    downloader.startDownload(
      url: '${ApiService.url}$url',
      headers: ApiService.headers.cast<String, String>(),
      filename: filename,
      onStatusChanged: (taskId, status) {
        if (status == TaskStatus.failed) {
          showToast(msg: "任务失败");
        }
      },
    );
  }

  static void dispose() {
    _refreshTimer?.cancel();
    _urlTimer?.cancel();
    _badgeSubscription?.cancel();
    Worker.closeTaskWebSocket();
  }
}
