import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/pages/task_check_page.dart';
import 'package:shine/pages/task_draw_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/theme.dart';

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
        border: Border.all(width: 1, color: mainColorGreenBule60),
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
              onTap: () async {},
            ),
            //task-check
            _buildBottomSheetItem(
              icon: Icons.checklist,
              title: '任务清查',
              onTap: () async {
                Navigator.of(context).pop();
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
            _buildBottomSheetItem(
              icon: Icons.ballot,
              title: '投票',
              onTap: () async {
                Navigator.of(context).pop();
                await globalNavigatorKey.currentState?.pushNamed('/task/vote');
              },
            ),
          ],
        ),
      );
    },
  );
}
