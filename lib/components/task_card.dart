import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/pages/task_check_page.dart';
import 'package:shine/pages/task_upload_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_task.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/time.dart';

class TaskCard extends StatelessWidget {
  final GestureTapCallback? onPress;
  final GestureLongPressCallback? onLongPress;
  final VoidCallback? onDelete;
  final TaskStorageData taskData;
  const TaskCard({
    super.key,
    this.onPress,
    this.onLongPress,
    required this.taskData,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final onPressMap = <Type, GestureTapCallback>{
      CheckTaskStorageData: () async {
        final data = taskData as CheckTaskStorageData;
        await globalNavigatorKey.currentState?.pushNamed(
          '/task/check',
          arguments: TaskCheckPageArgs(data: data),
        );
        HomePageRefreshNotifier.refreshTask();
      },
      UploadTaskStorageData: () async {
        final data = taskData as UploadTaskStorageData;
        if (ApiService.userType != "admin") {
          showToast(msg: "只有管理员能查看此任务");
          return;
        }
        await globalNavigatorKey.currentState?.pushNamed(
          '/task/upload',
          arguments: TaskUploadPageArgs(data: data),
        );
        HomePageRefreshNotifier.refreshTask();
      },
    };
    final onDeleteMap = <Type, VoidCallback>{
      CheckTaskStorageData: () async {
        TaskStorage.delCheckTask(id: taskData.id).then((_) async {
          await showToast(
            msg: "删除任务${taskData.title}成功",
            duration: Duration(milliseconds: 500),
          );
          HomePageRefreshNotifier.refreshTask();
        });
      },
      UploadTaskStorageData: () async {
        ApiTask.deleteTask(taskId: taskData.id).then((_) async {
          await showToast(
            msg: "删除任务${taskData.title}成功",
            duration: Duration(milliseconds: 500),
          );
          HomePageRefreshNotifier.refreshTask();
        });
      },
    };
    return Slidable(
      endActionPane: ActionPane(
        extentRatio: 0.25,
        motion: ScrollMotion(),
        children: [
          SlidableAction(
            icon: Icons.delete,
            backgroundColor: mainColorRed,
            spacing: 20,
            borderRadius: BorderRadius.circular(20),
            onPressed: (context) {
              final deleteAction =
                  onDelete ?? onDeleteMap[taskData.runtimeType];
              if (deleteAction != null) deleteAction();
            },
          ),
        ],
      ),
      child: Card(
        elevation: 2,
        color: mainColorPurple,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: mainColorGreenBlue60,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPress ?? onPressMap[taskData.runtimeType],
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: blueLinearGradient,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: whiteLinearGradient,
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(1, 1),
                            color: mainColorPurple,
                            blurRadius: 2,
                          ),
                          BoxShadow(
                            offset: Offset(-1, -1),
                            color: deepColorPurple,
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: _buildTaskIcon(),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (taskData.personal)
                                Icon(Icons.lock, size: 20, color: bgColorLight),
                              Expanded(
                                child: Text(
                                  taskData.title,
                                  style: const TextStyle(
                                    fontFamily: 'SmileySans',
                                    fontSize: 16,
                                    color: bgColorLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          _buildTaskTag(),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildTaskInfo(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                bottomLine,
                _buildCreatedAt(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Icon _buildTaskIcon() {
    if (taskData is CheckTaskStorageData) {
      return Icon(
        Icons.checklist_rounded,
        size: largeIconSize,
        color: mainColorPurple,
      );
    }
    if (taskData is UploadTaskStorageData) {
      return Icon(
        Icons.upload_rounded,
        size: largeIconSize,
        color: mainColorRed,
      );
    }
    return Icon(Icons.task, size: largeIconSize);
  }

  Widget _buildTaskTag() {
    late final String type;
    if (taskData is CheckTaskStorageData) {
      type = "任务清查";
    } else if (taskData is UploadTaskStorageData) {
      type = "作业收集";
    } else {
      type = "未知任务";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        gradient: purpleLinearGradient,
        boxShadow: [
          BoxShadow(
            color: bgColorLight60,
            spreadRadius: 1,
            offset: Offset(0.5, 0.5),
          ),
        ],
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: bgColorLight,
          fontFamily: 'SmileySans',
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCreatedAt() {
    final createdAt = taskData.createdAt;
    return Row(
      children: [
        Text(
          "创建于：",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 12,
            color: bgColorLight80,
          ),
          softWrap: true,
        ),
        Text(
          createdAt is DateTime ? getLocalTimeString(createdAt) : "未知时间",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 12,
            color: bgColorLight80,
          ),
          softWrap: true,
        ),
      ],
    );
  }

  List<Widget> _buildTaskInfo() {
    final List<Widget> result = [];
    if (taskData is CheckTaskStorageData) {
      final checkTaskData = taskData as CheckTaskStorageData;
      final countF = checkTaskData.finished.length;
      final countU = checkTaskData.unfinished.length;
      final countAll = countU + countF;
      result.addAll([
        Text(
          "完成进度：$countF/$countAll",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 14,
            color: bgColorLight,
          ),
        ),
      ]);
    }
    if (taskData is UploadTaskStorageData) {
      final data = taskData as UploadTaskStorageData;
      result.addAll([
        Text(
          "科目：${data.subjectName}",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 8,
            color: mainColorRed,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
        ),
        Text(
          "截止时间：${getLocalTimeString(data.endedAt)}(${getDayDifferenceString(data.endedAt)})",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 8,
            color: mainColorPurple,
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 2,
        ),
      ]);
    }
    return result;
  }
}
