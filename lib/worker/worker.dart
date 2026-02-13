import 'dart:async';

import 'package:shine/services/api.dart';
import 'package:shine/services/auth.dart';

class Worker {
  static Timer? _refreshTimer;
  static scheduleRefresh(Duration? duration) {
    const defaultDuration = Duration(minutes: 14, seconds: 30);
    _refreshTimer?.cancel();
    duration ??= defaultDuration;
    _refreshTimer = Timer(duration, () async {
      try {
        await ApiAuth.refresh();
      } catch (e) {
        await ApiService.reinit();
      }
      Worker.scheduleRefresh(defaultDuration);
    });
  }

  static stopRefresh() {
    _refreshTimer?.cancel();
  }
}
