import 'package:flutter/material.dart';
import 'package:shine/theme.dart';

const double likeFontSize = 24;

/// 用户名旁边的获赞数标记（只展示，不响应点击）
class LikeCountBadge extends StatelessWidget {
  /// 收到的赞总数，null 表示当前数据里没有这个字段
  final int? likeCount;

  /// 我今天是否赞过 TA
  final bool likedToday;

  const LikeCountBadge({
    super.key,
    required this.likeCount,
    this.likedToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final count = likeCount;
    if (count == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: likedToday ? deepColorOrange30 : bgColorLight60,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: likedToday ? deepColorOrange : mainColorGrey40,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            likedToday ? Icons.thumb_up : Icons.thumb_up_outlined,
            size: 14,
            color: likedToday ? darkColorPurple : bgColorLight80,
          ),
          const SizedBox(width: 3),
          Text(
            "$count",
            style: TextStyle(
              fontFamily: "SmileySans",
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: likedToday ? darkColorPurple : bgColorLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// 用户卡片上的点赞按键：每天可以给同一个同学点一个赞
class LikeActionButton extends StatelessWidget {
  /// 收到的赞总数，null 表示还没拿到数据
  final int? likeCount;

  /// 我今天是否赞过 TA
  final bool likedToday;

  /// 正在请求中
  final bool submitting;

  /// 是否可点（自己的名片 / 没有职务时不可点）
  final bool enabled;

  final VoidCallback? onTap;

  /// 长按撤回今天的赞
  final VoidCallback? onLongPress;

  const LikeActionButton({
    super.key,
    required this.likeCount,
    this.likedToday = false,
    this.submitting = false,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final count = likeCount;
    final label = likedToday ? "已赞" : "点赞";
    return GestureDetector(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        height: likeFontSize * 1.1,
        decoration: BoxDecoration(
          color: likedToday ? deepColorOrange80 : mainColorGreenBlue60,
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
            if (submitting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                likedToday ? Icons.thumb_up : Icons.thumb_up_outlined,
                color: Colors.white,
                size: likeFontSize * 0.8,
              ),
            const SizedBox(width: 3),
            Text(
              count == null ? label : "$label $count",
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'SmileySans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
