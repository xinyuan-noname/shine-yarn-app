class UserCache {
  static final Map<String, Map<String, dynamic>> _userCacheList = {};
  static clear() {
    _userCacheList.clear();
  }

  static void setFromGroupDataList(List<Map<String, dynamic>> dataList) {
    _userCacheList.clear();
    for (final data in dataList) {
      final id = data["id"];
      if (id is! String) continue;
      _userCacheList[id] = data;
    }
  }

  static String? getUsername(String id) {
    final user = _userCacheList[id];
    if (user == null) return null;
    return user['usernmae'];
  }

  static Map<String, dynamic>? getUser(String id) {
    return _userCacheList[id];
  }
}
