import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/theme.dart';

/// 下载进度弹窗：显示百分比，可随时取消。
///
/// 返回一个「关闭弹窗」的回调：下载结束（成功、失败或被用户取消）后调用一次。
/// 重复调用是安全的 —— 用户自己点了取消时，弹窗已经关掉，再调用什么都不做。
VoidCallback showDownloadProgressDialog({
  required BuildContext context,
  required ValueNotifier<int> progress,
  required String title,
  String description = '',
  String cancelText = '取消下载',
  VoidCallback? onCancel,
}) {
  var closed = false;
  // 拿住导航器状态而不是 buildContext：下载结束时原页面可能已经不在树上
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (_, value, __) {
            final percent = value.clamp(0, 100);
            return AlertDialog(
              backgroundColor: mainColorPurple,
              title: Text(title, style: dialogTitleStyle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      // 进度未知（-1）时显示不确定动画，而不是假装 0%
                      value: value < 0 ? null : percent / 100,
                      minHeight: 8,
                      backgroundColor: mainColorPurple80,
                      color: mainColorGreenBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value < 0 ? '正在准备下载…' : '已下载 $percent%',
                    style: dialogContentStyle,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(description, style: dialogContentSmallStyle),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  style: dialogButtonStyle,
                  onPressed: () {
                    closed = true;
                    Navigator.of(dialogContext).pop();
                    onCancel?.call();
                  },
                  child: Text(cancelText),
                ),
              ],
            );
          },
        ),
      );
    },
  ).whenComplete(() {
    // 用户用取消按钮关掉时，之后的 close() 不应该再 pop 别的东西
    closed = true;
  });
  return () {
    if (closed) return;
    closed = true;
    if (navigator.canPop()) navigator.pop();
  };
}
