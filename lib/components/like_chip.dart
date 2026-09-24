import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_like.dart';
import 'package:shine/theme.dart';

/// 用户卡片上的点赞标记：
///
/// - 展示该用户收到的总赞数，点一下就是给 TA 点赞；
/// - 每人每天对同一个用户只能点一次，已经赞过时高亮，再点只提示明天再来；
/// - 已经赞过时长按可以撤回今天的赞；
/// - [likeCount] 为 null 表示当前列表没有带获赞数（例如只读名单），此时不展示标记。
class LikeChip extends StatefulWidget {
  /// 被点赞的用户 ID
  final String userId;

  /// 服务端返回的获赞总数，null 表示数据里没有这个字段
  final int? likeCount;

  /// 服务端返回的「我今天是否赞过 TA」
  final bool likedToday;

  /// 是否可点按（只读列表里只展示数量）
  final bool interactive;

  const LikeChip({
    super.key,
    required this.userId,
    this.likeCount,
    this.likedToday = false,
    this.interactive = true,
  });

  @override
  State<LikeChip> createState() => _LikeChipState();
}

class _LikeChipState extends State<LikeChip> {
  late bool _hasCount = widget.likeCount != null;
  late int _likeCount = widget.likeCount ?? 0;
  late bool _likedToday = widget.likedToday;
  /// 最近一次从父级拿到的服务端数据，用来判断父级是否刷新了列表
  late int? _serverLikeCount = widget.likeCount;
  late bool _serverLikedToday = widget.likedToday;
  bool _submitting = false;

  @override
  void didUpdateWidget(covariant LikeChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedUser = oldWidget.userId != widget.userId;
    // 父级重新从服务端拉到数据时才覆盖本地状态，避免把刚点过的赞弹回去
    final refreshed =
        widget.likeCount != _serverLikeCount ||
        widget.likedToday != _serverLikedToday;
    if (changedUser || refreshed) {
      _serverLikeCount = widget.likeCount;
      _serverLikedToday = widget.likedToday;
      if (widget.likeCount != null) {
        _hasCount = true;
        _likeCount = widget.likeCount!;
      }
      _likedToday = widget.likedToday;
    }
  }

  bool get _isMine {
    if (widget.userId.isEmpty) return false;
    final myId = ApiService.safeUserId;
    return myId.isNotEmpty && myId == widget.userId;
  }

  Future<void> _like() async {
    if (!widget.interactive || _isMine || _submitting) return;
    if (_likedToday) {
      showToast(msg: "今天已经赞过TA了，明天再来吧");
      return;
    }
    setState(() {
      _submitting = true;
    });
    final result = await ApiLike.likeUser(widget.userId);
    if (!mounted) return;
    setState(() {
      _submitting = false;
    });
    if (result is! Map) {
      showToast(msg: result is String ? result : "点赞失败");
      return;
    }
    final count = result["likeCount"];
    final alreadyLiked = result["alreadyLiked"] == true;
    setState(() {
      if (count is int) {
        _likeCount = count;
        _hasCount = true;
      }
      _likedToday = true;
      // 与服务端对齐，父级再次刷新时不会把状态改回去
      _serverLikeCount = _hasCount ? _likeCount : null;
      _serverLikedToday = true;
    });
    showToast(msg: alreadyLiked ? "今天已经赞过TA了" : "点赞成功");
  }

  /// 长按撤回今天给出的赞（撤回后今天还能重新点）
  Future<void> _cancelLike() async {
    if (!widget.interactive || _isMine || _submitting) return;
    final confirm = await showConfirmDialog(
      context: context,
      title: "撤回点赞",
      content: "确定撤回今天给TA的赞吗？撤回后今天还可以重新点。",
    );
    if (!confirm || !mounted) return;
    setState(() {
      _submitting = true;
    });
    final result = await ApiLike.cancelLike(widget.userId);
    if (!mounted) return;
    setState(() {
      _submitting = false;
    });
    if (result is! Map) {
      showToast(msg: result is String ? result : "取消失败");
      return;
    }
    final count = result["likeCount"];
    final canceled = result["canceled"] == true;
    setState(() {
      if (count is int) {
        _likeCount = count;
        _hasCount = true;
      }
      _likedToday = false;
      _serverLikeCount = _hasCount ? _likeCount : null;
      _serverLikedToday = false;
    });
    showToast(msg: canceled ? "已撤回今天的赞" : "今天还没有赞过TA");
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCount) return const SizedBox.shrink();
    final liked = _likedToday;
    final canTap = widget.interactive && !_isMine;
    return GestureDetector(
      onTap: canTap ? _like : null,
      onLongPress: canTap && liked ? _cancelLike : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: liked ? deepColorOrange30 : bgColorLight60,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: liked ? deepColorOrange : mainColorGrey40,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_submitting)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.6),
              )
            else
              Icon(
                liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 14,
                color: liked ? darkColorPurple : bgColorLight80,
              ),
            const SizedBox(width: 3),
            Text(
              "$_likeCount",
              style: TextStyle(
                fontFamily: "SmileySans",
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: liked ? darkColorPurple : bgColorLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
