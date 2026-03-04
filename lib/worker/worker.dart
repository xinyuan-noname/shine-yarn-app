import 'dart:async';
import 'dart:typed_data';

import 'package:shine/services/api.dart';
import 'package:shine/services/api_auth.dart';
import 'package:shine/services/api_group.dart';
import 'package:shine/services/api_profiles.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/storage/profile_storage.dart';

class Worker {
  static Timer? _refreshTimer;
  static Timer? _urlTimer;
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
      Worker.scheduleRefresh(defaultDuration);
    });
  }

  static scheduleRefreshNow() {
    Worker.scheduleRefresh(Duration(milliseconds: 50));
  }

  static stopRefresh() {
    _refreshTimer?.cancel();
  }

  static scheduleUrl(Duration? duration) {
    const defaultDuration = Duration(seconds: 3);
    _urlTimer?.cancel();
    duration ??= defaultDuration;
    _urlTimer = Timer(duration, () async {
      final url = await ApiService.getBaseUrl();
      if (url != ApiService.url) {
        print("更换url为:$url");
        ApiService.setBaseUrl(url);
      }
      Worker.scheduleUrl(defaultDuration);
    });
  }

  static scheduleUrlNow() {
    Worker.scheduleUrl(Duration(milliseconds: 50));
  }

  static syncMyAvatar() async {
    final avatarData = await ApiProfiles.getMyAvatar();
    if (avatarData is Uint8List) await ProfileStorage.saveAvatar(avatarData);
  }

  static syncMyProfile() async {
    final result = await ApiProfiles.getMyProfile();
    if (result is Map) {
      final String? id = result["id"];
      final String? gender = result["gender"];
      final String? username = result["username"];
      final bool? passwordRequired = result["passwordRequired"];
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
    }
  }

  static syncAllUser() async {
    final userInfoList = await ApiProfiles.getUserInfo();
    if (userInfoList is List) await ProfileStorage.saveUserList(userInfoList);
  }

  static syncMyData() async {
    await Worker.syncMyAvatar();
    await Worker.syncMyProfile();
  }

  static syncGlobalGroup({bool force = false}) async {
    final list = GroupStorageKey.values;
    for (final nameKeyEnum in list) {
      if (!force) {
        final storage = await GroupStorage.getGroupUserList(nameKeyEnum);
        if (storage is List) continue;
      }
      final result = await ApiGroup.getGlobalGroupData(nameKeyEnum);
      if(result is List) GroupStorage.saveGroupUserList(nameKeyEnum, result);
    }
  }

  static startTaskWebSocket() {
    WsTask.start();
  }
}
