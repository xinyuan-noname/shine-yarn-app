import 'package:shine/services/api.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/utils/to_do_author_utils.dart';

/// 当前登录用户在事项表里的身份：昵称 / 职务 / 用户 ID / 是否管理员。
///
/// 事项表所有人都能发布后，来源统一写昵称，判断「这条事项是不是我发的」
/// 要用到这几个标识；各处零散去读容易漏，统一在这里取一次。
class ToDoViewer {
  /// 昵称，未同步到时为空串
  final String username;

  /// 职务，普通同学为 null
  final String? position;

  /// 用户 ID，未登录为空
  final String? id;

  final bool isAdmin;

  const ToDoViewer({
    required this.username,
    this.position,
    this.id,
    this.isAdmin = false,
  });

  /// 读取当前用户身份（每次读取都拿最新的，避免登录切换后用到旧昵称）
  static Future<ToDoViewer> load() async {
    final username = await ProfileStorage.getName();
    String? position;
    String? id;
    var isAdmin = false;
    try {
      final userId = ApiService.userId;
      id = userId.isEmpty ? null : userId;
      position = ApiService.position;
      isAdmin = ApiService.userType == 'admin';
    } catch (e) {
      // 令牌异常时退化成「没职务的普通同学」，
      // 不能因为读个身份就把删除 / 编辑按钮点崩
    }
    return ToDoViewer(
      username: username,
      position: position,
      id: id,
      isAdmin: isAdmin,
    );
  }

  /// 发布事项时写入的来源
  String get publisherSource =>
      toDoPublisherSource(username: username, position: position);

  /// 能否删除 / 编辑来源为 [itemSource] 的事项
  bool canOperate(String itemSource) => canOperateToDoItem(
    itemSource: itemSource,
    username: username,
    position: position,
    userId: id,
    isAdmin: isAdmin,
  );
}
