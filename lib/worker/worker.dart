import 'dart:async';

import 'package:shine/services/auth.dart';

class Worker {
  static Timer? _refreshTimer;
  static scheduleRefresh(Duration? duration) {
    const defaultDuration = Duration(minutes: 14, seconds: 30);
    _refreshTimer?.cancel();
    duration ??= defaultDuration;
    _refreshTimer = Timer(duration, () async {
      ApiAuth.refresh();
      Worker.scheduleRefresh(defaultDuration);
    });
  }

  static stopRefresh() {
    _refreshTimer?.cancel();
  }
}
