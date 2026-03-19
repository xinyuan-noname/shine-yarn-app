class UserCache {
  static final Map<String, Map<String, dynamic>> _userCacheMap = {};
  static clear() {
    _userCacheMap.clear();
  }

  static void setFromGroupDataList(List<Map<String, dynamic>> dataList) {
    _userCacheMap.clear();
    for (final data in dataList) {
      final id = data["id"];
      if (id is! String) continue;
      _userCacheMap[id] = data;
    }
  }

  static String? getUsername(String id) {
    final user = _userCacheMap[id];
    if (user == null) return null;
    if(user['username'] is String) return user['username'];
    return null;
  }

  static Map<String, dynamic>? getUser(String id) {
    return _userCacheMap[id];
  }

  static List<Map<String, dynamic>> getUserList() {
    return _userCacheMap.values.toList();
  }

  static List<String> getIdList() {
    return _userCacheMap.keys.toList();
  }
}
