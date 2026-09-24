/// 事项表里「这条事项是谁发的」的判断与展示。
///
/// 事项改为所有人都能发布后，服务端写入的 source 统一是发布者昵称；
/// 但历史数据里存的是职务（班长 / 学委 …），更早的接口也可能回传用户 ID，
/// 所以三种标识都当作「我」来匹配。
library;

/// 来源缺失时的展示文案，避免卡片右下角出现空行
const String unknownToDoAuthorLabel = '同学';

/// [itemSource] 是否是当前用户发布的
///
/// 来源为空时无法判断作者，一律不算自己的，避免误删同学发的事项。
bool isMyToDoItem({
  required String itemSource,
  required String? username,
  String? position,
  String? userId,
}) {
  final source = itemSource.trim();
  if (source.isEmpty) return false;
  return _sameIdentity(source, username) ||
      _sameIdentity(source, position) ||
      _sameIdentity(source, userId);
}

/// 是否允许删除 / 编辑该事项：作者本人可以，管理员可以管理全部事项
bool canOperateToDoItem({
  required String itemSource,
  required String? username,
  String? position,
  String? userId,
  bool isAdmin = false,
}) {
  if (isAdmin) return true;
  return isMyToDoItem(
    itemSource: itemSource,
    username: username,
    position: position,
    userId: userId,
  );
}

/// 卡片上展示的来源：优先昵称，来源为空时给个兜底文案
String toDoSourceLabel(String source) {
  final trimmed = source.trim();
  return trimmed.isEmpty ? unknownToDoAuthorLabel : trimmed;
}

/// 发布事项时写入的 source：有昵称用昵称，昵称为空时退回职务
String toDoPublisherSource({required String? username, String? position}) {
  final name = username?.trim() ?? '';
  if (name.isNotEmpty) return name;
  return position?.trim() ?? '';
}

/// 两个标识是否指向同一个人（忽略首尾空白与大小写）
bool _sameIdentity(String source, String? candidate) {
  final value = candidate?.trim() ?? '';
  if (value.isEmpty) return false;
  return value == source || value.toLowerCase() == source.toLowerCase();
}
