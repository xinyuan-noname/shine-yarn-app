import 'package:flutter/material.dart';
import 'package:shine/components/task_card.dart';
import 'package:shine/pages/task_check_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';

class TaskView extends StatelessWidget {
  final RefreshCallback onRefresh;
  final List<TaskStorageData> taskList;
  const TaskView({
    super.key,
    required this.onRefresh,
    required this.taskList,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: mainColorPurple90,
      backgroundColor: bgColorLight,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: viewPadding,
        itemCount: taskList.length,
        itemBuilder: (context, index) {
          final data = taskList[index];
          return TaskCard(
            taskData: data,
            onPress: () async {
              if (data is CheckTaskStorageData) {
                await globalNavigatorKey.currentState?.pushNamed(
                  '/task/check',
                  arguments: TaskCheckArgs(data: data),
                );
              }
            },
          );
        },
      ),
    );
  }
}
