import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shine/components/icon_button.dart';
import 'package:shine/components/line.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/pages/task_check_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/time.dart';

const double largeIconSize = 48;

class TaskCard extends StatelessWidget {
  final GestureTapCallback? onPress;
  final GestureLongPressCallback? onLongPress;
  final VoidCallback? onDelete;
  final TaskStorageData taskData;
  final VoidCallback? deleteCallback;
  const TaskCard({
    super.key,
    this.onPress,
    this.onLongPress,
    required this.taskData,
    this.onDelete,
    this.deleteCallback,
  });

  @override
  Widget build(BuildContext context) {
    final onPressMap = <Type, GestureTapCallback>{
      CheckTaskStorageData: () async {
        final CheckTaskStorageData data = taskData as CheckTaskStorageData;
        await globalNavigatorKey.currentState?.pushNamed(
          '/task/check',
          arguments: TaskCheckArgs(data: data),
        );
        HomePageRefreshNotifier.refreshTask();
      },
    };
    final onDeleteMap = <Type, VoidCallback>{
      CheckTaskStorageData: () async {
        await TaskStorage.delCheckTask(id: taskData.id);
        HomePageRefreshNotifier.refreshTask();
      },
    };
    return Slidable(
      endActionPane: ActionPane(
        extentRatio: 0.25,
        motion: ScrollMotion(),
        children: [
          CardDeleteButton(
            onDelete: onDelete ?? onDeleteMap[taskData.runtimeType],
          ),
        ],
      ),
      child: Card(
        elevation: 2,
        color: mainColorPurple,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: mainColorGreenBule60,
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
                                Transform.translate(
                                  offset: Offset(0, 0),
                                  child: Icon(
                                    Icons.lock,
                                    size: 20,
                                    color: bgColorLight,
                                  ),
                                ),
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
    return Icon(Icons.task, size: largeIconSize);
  }

  Widget _buildTaskTag() {
    late final String type;
    if (taskData is CheckTaskStorageData) {
      type = "任务清查";
    } else {
      type = "未知任务";
    }
    return Container(
      margin: EdgeInsets.only(left: 10),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
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
    return result;
  }
}
