import 'dart:async';

import 'package:shine/services/api.dart';
import 'package:shine/services/auth.dart';
import 'package:shine/services/profiles.dart';
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
    const defaultDuration = Duration(minutes: 3);
    _urlTimer?.cancel();
    duration ??= defaultDuration;
    _urlTimer = Timer(duration, () async {
      final url = await ApiService.getBaseUrl();
      if (url != ApiService.url) {
        ApiService.setBaseUrl(url);
      }
      Worker.scheduleUrl(defaultDuration);
    });
  }

  static scheduleUrlNow() {
    Worker.scheduleUrl(Duration(milliseconds: 50));
  }

  static scheduleAvatar(String id) async {
    final avatarData = await ApiProfiles.getAvatar(id);
    await ProfileStorage.saveAvatar(avatarData);
  }
}
