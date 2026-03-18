import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/config/app_config.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/pages/task_check_page.dart';
import 'package:shine/pages/task_draw_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/time_utils.dart';

Widget _buildBottomSheetItem({
  required IconData icon,
  required String title,
  GestureTapCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: mainColorGreenBlue60),
        gradient: purpleLinearGradient,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: bgColorLight),
          const SizedBox(height: 4),
          Text(
            title,
            style: bottomSheetGridTitleTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Future<DateTime?> showWeekBottomSheet(
  BuildContext context, {
  required DateTime startedAt,
  required DateTime selectedDate,
}) {
  final completer = Completer<DateTime?>();
  final future = showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: mainColorPurple,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: 20,
          itemBuilder: (BuildContext context, int index) {
            DateTime date = startedAt.add(Duration(days: index * 7));
            return GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                completer.complete(date);
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(width: 1, color: mainColorGreenBlue60),
                  gradient: selectedDate.inSameWeek(date)
                      ? purpleLinearGradient
                      : null,
                  boxShadow: [
                    if (selectedDate.inSameWeek(date))
                      BoxShadow(color: mainColorOrange50, blurRadius: 5),
                  ],
                ),
                child: Text(
                  inCurrentWeek(date) ? "当前周" : "第${index + 1}周",
                  style: bottomSheetGridTitleTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      );
    },
  );
  future.then((_) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  });
  return completer.future;
}

Future<void> showTaskGridBottomSheet(BuildContext context) async {
  return await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: mainColorPurple,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildBottomSheetItem(
              icon: Icons.upload,
              title: '作业收集',
              onTap: () async {
                Navigator.of(context).pop();
                if (ApiService.userType != "admin") {
                  showToast(msg: "权限不足!");
                  return;
                }
                await globalNavigatorKey.currentState?.pushNamed(
                  '/task/upload',
                );
                HomePageRefreshNotifier.refreshTask();
              },
            ),
            //task-check
            _buildBottomSheetItem(
              icon: Icons.checklist,
              title: '任务清查',
              onTap: () async {
                Navigator.of(context).pop();
                if (ApiService.userType == "guest") {
                  showToast(msg: "游客(无密码登录用户)暂不支持发起任务");
                  return;
                }
                final result = await showGroupStorageKeySelectionDialog(
                  context: context,
                  title: "选择清查的群组",
                );
                if (result is GroupStorageKey) {
                  await globalNavigatorKey.currentState?.pushNamed(
                    '/task/check',
                    arguments: TaskCheckPageArgs(groupStorageKey: result),
                  );
                  HomePageRefreshNotifier.refreshTask();
                }
              },
            ),
            //task-draw
            _buildBottomSheetItem(
              icon: Icons.shuffle,
              title: '随机选人',
              onTap: () async {
                Navigator.of(context).pop();
                if (ApiService.userType == "guest") {
                  showToast(msg: "游客(无密码登录用户)暂不支持发起任务");
                  return;
                }
                final result = await showGroupStorageKeySelectionDialog(
                  context: context,
                  title: '选择一个群组作为本次选人的范围',
                );
                if (result is GroupStorageKey) {
                  await globalNavigatorKey.currentState?.pushNamed(
                    '/task/draw',
                    arguments: TaskDrawPageArgs(groupStorageKey: result),
                  );
                  HomePageRefreshNotifier.refreshTask();
                }
              },
            ),
            //
            if (!AppConfig.isProduction)
              _buildBottomSheetItem(
                icon: Icons.ballot,
                title: '投票',
                onTap: () async {
                  Navigator.of(context).pop();
                  if (ApiService.userType == "guest") {
                    showToast(msg: "游客(无密码登录用户)暂不支持发起任务");
                    return;
                  }
                  await globalNavigatorKey.currentState?.pushNamed(
                    '/task/vote',
                  );
                  HomePageRefreshNotifier.refreshTask();
                },
              ),
          ],
        ),
      );
    },
  );
}
