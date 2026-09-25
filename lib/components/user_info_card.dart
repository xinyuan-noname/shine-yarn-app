import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/like_widgets.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_like.dart';
import 'package:shine/theme.dart';

const double adminFontSize = 24;
const TextStyle adminUsernameTextStyle = TextStyle(
  fontFamily: 'SmileySans',
  fontSize: adminFontSize,
  color: mainColorGreenBlue,
);

class UserInfoCard extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  final bool? noOperation;
  final GestureTapCallback? onDelete;
  final GestureTapCallback? onEdit;
  final GestureTapCallback? onIssuePswdKey;
  final GestureTapCallback? onSendMessage;
  final GestureTapCallback? onPress;
  final GestureLongPressCallback? onLongPress;
  final bool useAvatar;
  const UserInfoCard({
    super.key,
    required this.userInfo,
    this.onDelete,
    this.onEdit,
    this.onIssuePswdKey,
    this.onSendMessage,
    this.onLongPress,
    this.onPress,
    this.noOperation,
    this.useAvatar = true,
  });

  @override
  State<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<UserInfoCard> {
  /// 获赞数：null 表示当前数据里没有带这个字段
  int? _likeCount;
  bool _likedToday = false;

  /// 最近一次从列表数据里读到的值，用来判断父级是否刷新了数据
  int? _serverLikeCount;
  bool _serverLikedToday = false;
  bool _likeSubmitting = false;

  Map<String, dynamic> get userInfo => widget.userInfo;
  bool? get noOperation => widget.noOperation;
  GestureTapCallback? get onDelete => widget.onDelete;
  GestureTapCallback? get onEdit => widget.onEdit;
  GestureTapCallback? get onIssuePswdKey => widget.onIssuePswdKey;
  GestureTapCallback? get onSendMessage => widget.onSendMessage;
  GestureTapCallback? get onPress => widget.onPress;
  GestureLongPressCallback? get onLongPress => widget.onLongPress;
  bool get useAvatar => widget.useAvatar;

  String get _userId {
    final id = userInfo['id'];
    return id is String ? id : "";
  }

  /// 没有职务的同学只能查看，不能点赞
  bool get _canLike {
    if (noOperation == true) return false;
    if (_userId.isEmpty) return false;
    final myId = ApiService.safeUserId;
    return myId.isNotEmpty && myId != _userId;
  }

  @override
  void initState() {
    super.initState();
    _adoptUserInfo();
  }

  @override
  void didUpdateWidget(covariant UserInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedUser = oldWidget.userInfo['id'] != userInfo['id'];
    // 列表重新从服务端拉到数据时才覆盖本地状态，避免把刚点过的赞弹回去
    final refreshed =
        (_likeCountFrom(userInfo) != _serverLikeCount) ||
        (_likedTodayFrom(userInfo) != _serverLikedToday);
    if (changedUser || refreshed) _adoptUserInfo();
  }

  int? _likeCountFrom(Map<String, dynamic> info) {
    final count = info['likeCount'];
    return count is int ? count : null;
  }

  bool _likedTodayFrom(Map<String, dynamic> info) => info['likedToday'] == true;

  void _adoptUserInfo() {
    _serverLikeCount = _likeCountFrom(userInfo);
    _serverLikedToday = _likedTodayFrom(userInfo);
    _likeCount = _serverLikeCount;
    _likedToday = _serverLikedToday;
  }

  /// 点赞：每人每天对同一个用户只能点一次
  Future<void> _like() async {
    if (!_canLike || _likeSubmitting) return;
    if (_likedToday) {
      showToast(msg: "今天已经赞过TA了，明天再来吧");
      return;
    }
    setState(() {
      _likeSubmitting = true;
    });
    final result = await ApiLike.likeUser(_userId);
    if (!mounted) return;
    setState(() {
      _likeSubmitting = false;
    });
    if (result is! Map) {
      // 失败原因（接口不存在 / 参数不合法）需要看清，提示停留久一点
      showToast(
        msg: result is String ? result : "点赞失败",
        duration: const Duration(seconds: 3),
      );
      return;
    }
    final count = result["likeCount"];
    final alreadyLiked = result["alreadyLiked"] == true;
    setState(() {
      if (count is int) _likeCount = count;
      _likedToday = true;
      _serverLikeCount = _likeCount;
      _serverLikedToday = true;
    });
    showToast(msg: alreadyLiked ? "今天已经赞过TA了" : "点赞成功");
  }

  /// 长按撤回今天给出的赞（撤回后今天还能重新点）
  Future<void> _cancelLike() async {
    if (!_canLike || _likeSubmitting || !_likedToday) return;
    final confirm = await showConfirmDialog(
      context: context,
      title: "撤回点赞",
      content: "确定撤回今天给TA的赞吗？撤回后今天还可以重新点。",
    );
    if (!confirm || !mounted) return;
    setState(() {
      _likeSubmitting = true;
    });
    final result = await ApiLike.cancelLike(_userId);
    if (!mounted) return;
    setState(() {
      _likeSubmitting = false;
    });
    if (result is! Map) {
      showToast(
        msg: result is String ? result : "取消失败",
        duration: const Duration(seconds: 3),
      );
      return;
    }
    final count = result["likeCount"];
    final canceled = result["canceled"] == true;
    setState(() {
      if (count is int) _likeCount = count;
      _likedToday = false;
      _serverLikeCount = _likeCount;
      _serverLikedToday = false;
    });
    showToast(msg: canceled ? "已撤回今天的赞" : "今天还没有赞过TA");
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onPress,
      child: Card(
        elevation: 2,
        color: mainColorPurple,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: mainColorGreenBlue60,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: purpleLinearGradient,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      children: [
                        if (useAvatar)
                          NetworkAvatar(id: userInfo['id'], radius: 40),
                        const SizedBox(height: 2),
                        if (userInfo['position'] is String)
                          Container(
                            margin: EdgeInsets.only(left: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 0.5,
                            ),
                            decoration: BoxDecoration(
                              gradient: redLinearGradientReversed,
                              boxShadow: [
                                BoxShadow(
                                  color: bgColorLight60,
                                  spreadRadius: 1,
                                  offset: Offset(0.5, 0.5),
                                ),
                              ],
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                            child: Text(
                              userInfo['position'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'SmileySans',
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                      ],
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUsernameRow(),
                        _buildIdRow(),
                        if (userInfo.containsKey("gender")) _buildGenderRow(),
                        if (userInfo["passwordRequired"] != null)
                          _buildPasswordRow(),
                      ],
                    ),
                  ],
                ),
                bottomLine,
                const SizedBox(height: 1),
                if (noOperation != true) _buildOperatorRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 左边按钮较多（点赞/发消息/签发令牌），窄屏时横向滚动，避免溢出
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 点赞按键：每天可以给同一个同学点一个赞，长按可以撤回
                if (_userId.isNotEmpty) ...[
                  LikeActionButton(
                    likeCount: _likeCount,
                    likedToday: _likedToday,
                    submitting: _likeSubmitting,
                    enabled: _canLike,
                    onTap: _like,
                    onLongPress: _likedToday ? _cancelLike : null,
                  ),
                  const SizedBox(width: 10),
                ],
                if (onSendMessage != null) _buildMessageButton(),
                if (onSendMessage != null && onIssuePswdKey != null)
                  const SizedBox(width: 10),
                if (onIssuePswdKey != null)
                  GestureDetector(
                    onTap: onIssuePswdKey,
                    child: Container(
                      alignment: Alignment.center,
                      height: adminFontSize * 1.1,
                      decoration: BoxDecoration(
                        color: mainColorGreenBlue60,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      child: Text(
                        "签发密码令牌",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'SmileySans',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              GestureDetector(
                onTap: onEdit,
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: adminFontSize * 1.1,
                ),
              ),
            SizedBox(height: adminFontSize * 1.1, width: 15),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: adminFontSize * 1.1,
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// 消息图标：点击后可以给该成员发送消息(支持匿名)
  Widget _buildMessageButton() {
    return GestureDetector(
      onTap: onSendMessage,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        height: adminFontSize * 1.1,
        decoration: BoxDecoration(
          color: mainColorGreenBlue60,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: bgColorLight60,
              spreadRadius: 0.5,
              offset: Offset(0.5, 0.5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.message_outlined,
              color: Colors.white,
              size: adminFontSize * 0.8,
            ),
            const SizedBox(width: 3),
            const Text(
              "发消息",
              style: TextStyle(color: Colors.white, fontFamily: 'SmileySans'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameRow() {
    return Row(
      children: [
        userInfo['userType'] == "admin"
            ? Icon(
                Icons.star,
                color: Colors.amberAccent,
                size: adminFontSize * 1.2,
              )
            : Icon(
                Icons.person,
                color: bgColorLight,
                size: adminFontSize * 1.2,
              ),
        const SizedBox(width: 5),
        Text(userInfo['username'] ?? "??", style: adminUsernameTextStyle),
        // 用户名旁边直接显示获赞数
        LikeCountBadge(likeCount: _likeCount, likedToday: _likedToday),
      ],
    );
  }

  Widget _buildIdRow() {
    return Row(
      children: [
        Text("学号", style: cardItemTextStyle),
        Text(":", style: cardItemTextStyle),
        const SizedBox(width: 5),
        Text(userInfo['id'], style: cardItemTextStyle),
      ],
    );
  }

  Widget _buildGenderRow() {
    return Row(
      children: [
        Text("性别", style: cardItemTextStyle),
        Text(":", style: cardItemTextStyle),
        const SizedBox(width: 5),
        Text(
          userInfo['gender'] == "male"
              ? "男"
              : userInfo["gender"] == "female"
              ? "女"
              : "无可奉告",
          style: cardItemTextStyle,
        ),
        Transform.rotate(
          angle: math.pi / 24,
          child: userInfo['gender'] == "male"
              ? Icon(
                  Icons.male_rounded,
                  color: bgColorLight80,
                  size: adminFontSize,
                )
              : userInfo["gender"] == "female"
              ? Transform.translate(
                  offset: const Offset(-3, 0),
                  child: Icon(
                    Icons.female_rounded,
                    color: bgColorLight80,
                    size: adminFontSize,
                  ),
                )
              : Transform.translate(
                  offset: const Offset(-4, 0),
                  child: Icon(
                    Icons.question_mark_rounded,
                    color: bgColorLight80,
                    size: adminFontSize,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPasswordRow() {
    return Row(
      children: [
        Text("强制密码登录", style: cardItemTextStyle),
        Text(":", style: cardItemTextStyle),
        const SizedBox(width: 5),
        Text(
          userInfo['passwordRequired'] == true ? "是" : "否",
          style: cardItemTextStyle,
        ),
      ],
    );
  }
}
