import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/pages/notice_upload_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/time_utils.dart';
import 'package:shine/utils/upload_utils.dart';

class NoticeCard extends StatelessWidget {
  final GestureTapCallback? onPress;

  final GestureLongPressCallback? onLongPress;

  final UploadData? uploadData;

  final TaskStorageData taskData;
  const NoticeCard({
    super.key,
    this.onPress,
    this.onLongPress,
    this.uploadData,
    required this.taskData,
  });

  @override
  Widget build(BuildContext context) {
    final onPressMap = <Type, GestureTapCallback>{
      UploadTaskStorageData: () async {
        final data = taskData as UploadTaskStorageData;
        await globalNavigatorKey.currentState?.pushNamed(
          '/notice/upload',
          arguments: NoticeUploadPageArgs(data: data, uploadData: uploadData),
        );
        HomePageRefreshNotifier.refreshMessage();
      },
    };
    return Card(
      elevation: 2,
      color: mainColorPurple,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: darkColorPurple,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPress ?? onPressMap[taskData.runtimeType],
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: whiteLinearGradient,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    alignment: Alignment.center,
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
                  SizedBox(height: 10),
                  _buildTaskTag(),
                ],
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
        ),
      ),
    );
  }

  Widget _buildTaskTag() {
    late final String type;
    if (taskData is UploadTaskStorageData) {
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

  List<Widget> _buildTaskInfo() {
    final List<Widget> result = [];
    if (taskData is UploadTaskStorageData) {
      final data = taskData as UploadTaskStorageData;
      final finished = uploadData != null;
      result.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              data.title,
              style: const TextStyle(fontFamily: 'SmileySans', fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: finished ? redLinearGradient : greyLinearGradient,
                boxShadow: [BoxShadow(color: mainColorPurple, blurRadius: 5)],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                finished ? "已完成" : "未完成",
                style: const TextStyle(
                  fontFamily: 'SmileySans',
                  fontSize: 12,
                  color: bgColorLight,
                ),
              ),
            ),
          ],
        ),
        Text(
          "科目：${data.subjectName}",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 10,
            color: mainColorRed,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.bold,
          ),
        ),
        Wrap(
          children: [
            Text(
              "截止时间：",
              style: const TextStyle(
                fontFamily: 'SmileySans',
                fontSize: 10,
                color: mainColorPurple,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${getLocalTimeString(data.endedAt)}(${getDayDifferenceString(data.endedAt)})',
              style: const TextStyle(
                fontFamily: 'SmileySans',
                fontSize: 10,
                color: mainColorPurple,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            bottomLineSmall,
            SizedBox(height: 2),
          ],
        ),
      ]);
    }
    return result;
  }

  Widget _buildTaskIcon() {
    if (taskData is UploadTaskStorageData) {
      final data = taskData as UploadTaskStorageData;
      if (data.source == "admin") {
        return Icon(Icons.star, size: largeIconSize, color: mainColorOrange);
      }
      return NetworkAvatar(id: data.source, radius: largeIconSize);
    }
    return Icon(Icons.task, size: largeIconSize);
  }
}
