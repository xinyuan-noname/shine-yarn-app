import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shine/components/bottom_sheet.dart';
import 'package:shine/components/floating_action_button_widget.dart';
import 'package:shine/components/task_card.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';

class TaskView extends StatelessWidget {
  final RefreshCallback onRefresh;
  final List<TaskStorageData> taskList;
  const TaskView({super.key, required this.onRefresh, required this.taskList});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          color: mainColorPurple90,
          backgroundColor: bgColorLight,
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: viewPadding,
            itemCount: max(taskList.length, 1),
            itemBuilder: (context, index) {
              if (taskList.isEmpty) {
                return Container(
                  alignment: Alignment.center,
                  child: const Text(
                    "暂没有任务哟，想搞点儿事情可以点击+号哟",
                    style: viewEmptyTextStyle,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final data = taskList[index];
              return TaskCard(taskData: data);
            },
          ),
        ),
        Positioned(
          right: 0,
          bottom: 20,
          child: FloatingActionButtonWidget(
            onTap: () {
              showTaskGridBottomSheet(context);
            },
          ),
        ),
      ],
    );
  }
}
