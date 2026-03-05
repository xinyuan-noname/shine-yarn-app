import 'package:flutter/material.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/time.dart';

const double largeIconSize = 48;

class TaskCard extends StatelessWidget {
  final GestureTapCallback? onPress;
  final GestureLongPressCallback? onLongPress;
  final TaskStorageData taskData;
  const TaskCard({
    super.key,
    this.onPress,
    this.onLongPress,
    required this.taskData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onPress,
      child: Card(
        elevation: 2,
        color: mainColorPurple,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: mainColorGreenBule60,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: blueLinearGradient,
          ),
          child: Padding(
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
                            color: darkColorPurple,
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: _buildTaskIcon(),
                    ),
                    SizedBox(width: 20),
                    Column(
                      children: [
                        Wrap(
                          children: [
                            Text(
                              taskData.title,
                              style: const TextStyle(
                                fontFamily: 'SmileySans',
                                fontSize: 20,
                                color: bgColorLight,
                              ),
                            ),
                            if (taskData.personal)
                              Transform.translate(
                                offset: Offset(4, 3),
                                child: Icon(
                                  Icons.lock,
                                  size: 24,
                                  color: bgColorLight,
                                ),
                              ),
                          ],
                        ),
                        _buildTaskTag(),
                      ],
                    ),
                    SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildTaskInfo(),
                    ),
                  ],
                ),
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

  List<Widget> _buildTaskInfo() {
    final List<Widget> result = [];
    final createdAt = taskData.createdAt;
    final createdWidget = Wrap(
      direction: Axis.vertical,
      children: [
        Text(
          "创建于：",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 10,
            color: bgColorLight80,
          ),
          softWrap: true,
        ),
        Text(
          createdAt is DateTime ? getLocalTimeString(createdAt) : "未知时间",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 10,
            color: bgColorLight80,
          ),
          softWrap: true,
        ),
      ],
    );
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
        createdWidget,
      ]);
    }
    return result;
  }
}
