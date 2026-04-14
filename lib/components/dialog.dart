import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/input.dart';
import 'package:shine/models/course_data.dart';
import 'package:shine/routes.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/message_utils.dart';

const dialogTitleStyle = TextStyle(
  fontSize: 20,
  fontFamily: 'SmileySans',
  fontWeight: FontWeight.w500,
);
const dialogContentStyle = TextStyle(
  fontSize: 16,
  fontFamily: 'SmileySans',
  color: bgColorLight60,
);
const dialogContentSmallStyle = TextStyle(
  fontSize: 11,
  fontFamily: 'SmileySans',
  color: bgColorLight60,
);
const dialogActionStyle = TextStyle(
  fontFamily: 'SmileySans',
  color: bgColorLight80,
  fontSize: 15,
);
final dialogButtonStyle = TextButton.styleFrom(
  backgroundColor: mainColorGreenBlue60,
  foregroundColor: bgColorLight80,
  textStyle: dialogActionStyle,
);
Future showMessageDialog(
  BuildContext context,
  ValueNotifier<String> message, {
  bool barrierDismissible = false,
}) {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => ValueListenableBuilder<String>(
      valueListenable: message,
      builder: (_, text, __) => Dialog(
        child: Container(
          height: 72,
          alignment: Alignment.center,
          child: Text(text),
        ),
      ),
    ),
  );
}

Future<void> showLoadingDialog({
  required BuildContext context,
  required ValueNotifier<String> message,
  required Future<String?> request,
}) async {
  final future = showMessageDialog(context, message);
  sendRequestAndChangeMessage(
    message,
    request: request,
    initMessageList: [],
    messageList: ["正在加载中.", "正在加载中..", "正在加载中..."],
    successMessage: "加载成功",
    successMessageDuration: Duration(milliseconds: 300),
    failMessageDuration: Duration(milliseconds: 800),
  ).then((_) {
    Navigator.of(context).pop();
  });
  return await future;
}

Future<void> showAlertDialog({
  required BuildContext context,
  required String title,
  required String content,
  VoidCallback? onYes,
  String confirmText = '确定',
}) async {
  return await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: mainColorPurple,
        title: Text(title, style: dialogTitleStyle),
        content: Text(content, style: dialogContentStyle),
        actions: [
          TextButton(
            style: dialogButtonStyle,
            onPressed: onYes ?? () => Navigator.of(context).pop(),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}

Future<void> showScheduleDialog({
  required BuildContext context,
  required String courseName,
  required String location,
  required CourseBasicInfo courseInfo,
  required CourseSchedule courseSchedule,
  ScheduleData? scheduleData,
  VoidCallback? onYes,
  String confirmText = '确定',
  required Function(String) onJump,
}) async {
  final courseAllName = courseInfo.subjectName.replaceAll("实验", "");
  final teachers = courseInfo.teachers.join("，");
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: mainColorPurple,
        title: Text(courseName, style: dialogTitleStyle),
        content: Container(
          padding: EdgeInsets.all(0),
          child: Wrap(
            direction: Axis.vertical,
            children: [
              Text("科目：$courseAllName", style: dialogContentSmallStyle),
              SizedBox(height: 11),
              Text("教师：$teachers", style: dialogContentSmallStyle),
              SizedBox(height: 11),
              Text("上课地点：$location", style: dialogContentSmallStyle),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: dialogButtonStyle,
            onPressed: onYes ?? () => Navigator.of(context).pop(),
            child: Text("关闭"),
          ),
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.of(context).pop();
              onJump(courseName);
            },
            child: Text("查看资源"),
          ),
        ],
      );
    },
  );
}

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = '确定',
  String cancelText = '取消',
}) async {
  final result = await showDialog<bool?>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: mainColorPurple,
        title: Text(title, style: dialogTitleStyle),
        content: Text(content, style: dialogContentStyle),
        actions: [
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(cancelText),
          ),
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

Future<String?> showPromptDialog({
  required BuildContext context,
  required String title,
  required String label,
  String? initValue,
  String confirmText = '确定',
  String cancelText = '取消',
  int? min,
  int? max,
}) {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();
  final completer = Completer<String?>();
  final future = showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: mainColorPurple,
        title: Text(title, style: dialogTitleStyle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: formKey,
              child: Input(
                autofocus: true,
                name: "prompt",
                label: label,
                minLength: min ?? 1,
                maxLength: max ?? 32,
                controller: controller,
                hintStyle: hintStyle,
                inputStyle: inputStyle,
                labelStyle: labelStyle,
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 1.0, color: Colors.grey),
                ),
                color: mainColorPurple90,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r"\s")),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(null);
            },
            child: Text(cancelText),
          ),
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              final result = controller.text;
              if (formKey.currentState!.validate() && result.isNotEmpty) {
                Navigator.of(context).pop();
                completer.complete(result);
              }
            },
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  if (initValue is String) {
    controller.text = initValue;
  }
  future.then((_) {
    if (completer.isCompleted) return;
    completer.complete(null);
  });
  return completer.future;
}

Future<T?> showDropDownDialog<T>({
  required BuildContext context,
  required String title,
  required List<(T, String)> items,
  required T initialValue,
  String confirmText = '确定',
  String cancelText = '取消',
}) {
  final completer = Completer<T?>();
  T selectedValue = initialValue;

  final future = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: mainColorPurple,
        title: Text(title, style: dialogTitleStyle),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DropdownButtonFormField<T>(
              initialValue: selectedValue,
              onChanged: (T? newValue) {
                if (newValue == null) return;
                selectedValue = newValue;
                setState(() {});
              },
              dropdownColor: mainColorPurple60,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item.$1,
                  child: Text(item.$2, style: dialogContentStyle),
                );
              }).toList(),
              decoration: InputDecoration(
                hintStyle: hintStyle,
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 1.0, color: Colors.grey),
                ),
                filled: true,
                fillColor: mainColorPurple90,
              ),
            );
          },
        ),
        actions: [
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(null);
            },
            child: Text(cancelText),
          ),
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(selectedValue);
            },
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  future.then((_) {
    if (completer.isCompleted) return;
    completer.complete(null);
  });
  return completer.future;
}

Future<GroupStorageKey?> showGroupStorageKeySelectionDialog({
  required BuildContext context,
  required String title,
  GroupStorageKey initialValue = GroupStorageKey.entire,
}) {
  return showDropDownDialog<GroupStorageKey>(
    context: context,
    title: title,
    items: [
      (GroupStorageKey.entire, "所有学生"),
      (GroupStorageKey.male, "所有男生"),
      (GroupStorageKey.female, "所有女生"),
      (GroupStorageKey.position, "所有班委"),
      (GroupStorageKey.user, "所有非班委"),
      (GroupStorageKey.admin, "所有管理员"),
    ],
    initialValue: initialValue,
  );
}

Future showAlertIsInDevelopmentDialog(BuildContext context) async {
  return await showAlertDialog(
    context: context,
    title: "本功能正在开发中",
    content: "请酌情使用",
  );
}

Future showGotoAdminDialog(BuildContext context) async {
  final result = await showConfirmDialog(
    context: context,
    title: '即将进入超级管理员界面!',
    content: '确定要进入吗？',
  );
  if (!result) return null;
  return await globalNavigatorKey.currentState?.pushNamed('/admin');
}

Future<String?> showUnfinishedTaskSaveDialog({
  required BuildContext context,
  int min = 2,
  int max = 8,
}) {
  return showPromptDialog(
    context: context,
    title: "该任务暂未完成，是否保存？(名称在$min到$max个字符之间)",
    label: "任务名称",
    confirmText: "保存",
    cancelText: "退出",
    min: min,
    max: max,
    initValue: '',
  );
}

Future<void> showMyAboutDialog(BuildContext context) async {
  return showAboutDialog(
    context: context,
    applicationName: '闪纺',
    applicationVersion: '1.0.0',
    applicationIcon: const FlutterLogo(size: 64),
    children: [
      Container(
        padding: const EdgeInsets.only(top: 20.0),
        child: const Text(
          '闪纺是一个由Flutter构建的应用，仅供内部学习使用，无作者许可，不得外传！',
          style: TextStyle(fontSize: 16, fontFamily: 'SmileySans'),
        ),
      ),
      Container(
        padding: const EdgeInsets.only(top: 20.0),
        child: const Text(
          'PC端：Flutter',
          style: TextStyle(fontSize: 16, fontFamily: 'SmileySans'),
        ),
      ),
      const Text(
        '移动端：Flutter',
        style: TextStyle(fontSize: 16, fontFamily: 'SmileySans'),
      ),
      Container(
        padding: const EdgeInsets.only(top: 20.0),
        child: const Text(
          '服务器网络服务：Cloudflared Tunnel+Github',
          style: TextStyle(fontSize: 16, fontFamily: 'SmileySans'),
        ),
      ),
      const Text(
        '服务器环境：Termux(proot-distro:Ubuntu)',
        style: TextStyle(fontSize: 16, fontFamily: 'SmileySans'),
      ),
      const Text(
        '服务器架构：Express+Redis+Sqlite3',
        style: TextStyle(fontSize: 16, fontFamily: 'SmileySans'),
      ),
      Container(
        padding: const EdgeInsets.only(top: 20.0),
        child: const Text(
          '开发相关：VS code+Git+SFTP',
          style: TextStyle(fontSize: 16, fontFamily: 'SmileySans'),
        ),
      ),
    ],
  );
}

Future<CourseData?> showCourseDataEditDialog({
  required BuildContext context,
  required CourseData courseData,
}) async {
  final formKey = GlobalKey<FormState>();

  // 基本信息控制器
  final subjectNameController = TextEditingController(
    text: courseData.basicInfo.subjectName,
  );
  final courseTypeController = TextEditingController(
    text: courseData.basicInfo.courseType,
  );
  final teachersController = TextEditingController(
    text: courseData.basicInfo.teachers.join('，'),
  );
  final creditController = TextEditingController(
    text: courseData.basicInfo.credit?.toString() ?? '',
  );
  final aliasController = TextEditingController(
    text: courseData.basicInfo.alias ?? '',
  );
  final semesterController = TextEditingController(
    text: courseData.basicInfo.semester ?? '',
  );

  // 时间安排列表（可变副本）
  final scheduleList = List<CourseSchedule>.from(courseData.schedule);

  final completer = Completer<CourseData?>();

  final future = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: mainColorPurple,
            title: Text('编辑课程数据', style: dialogTitleStyle),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '基本信息',
                      style: dialogContentStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Input(
                      name: "subjectName",
                      label: "科目名称",
                      controller: subjectNameController,
                      hintStyle: hintStyle,
                      inputStyle: inputStyle,
                      labelStyle: labelStyle,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.grey),
                      ),
                      color: mainColorPurple90,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入科目名称';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    Input(
                      name: "courseType",
                      label: "课程类型",
                      controller: courseTypeController,
                      hintStyle: hintStyle,
                      inputStyle: inputStyle,
                      labelStyle: labelStyle,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.grey),
                      ),
                      color: mainColorPurple90,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入课程类型';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    Input(
                      name: "teachers",
                      label: "教师（多个用逗号分隔）",
                      controller: teachersController,
                      hintStyle: hintStyle,
                      inputStyle: inputStyle,
                      labelStyle: labelStyle,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.grey),
                      ),
                      color: mainColorPurple90,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入教师姓名';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    Input(
                      name: "credit",
                      label: "学分",
                      controller: creditController,
                      hintStyle: hintStyle,
                      inputStyle: inputStyle,
                      labelStyle: labelStyle,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.grey),
                      ),
                      color: mainColorPurple90,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 12),
                    Input(
                      name: "alias",
                      label: "别名（可选）",
                      controller: aliasController,
                      hintStyle: hintStyle,
                      inputStyle: inputStyle,
                      labelStyle: labelStyle,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.grey),
                      ),
                      color: mainColorPurple90,
                    ),
                    SizedBox(height: 12),
                    Input(
                      name: "semester",
                      label: "学期（可选）",
                      controller: semesterController,
                      hintStyle: hintStyle,
                      inputStyle: inputStyle,
                      labelStyle: labelStyle,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.grey),
                      ),
                      color: mainColorPurple90,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '时间安排',
                          style: dialogContentStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          icon: Icon(Icons.add, size: 18, color: bgColorLight80),
                          label: Text('添加', style: dialogActionStyle),
                          style: dialogButtonStyle,
                          onPressed: () {
                            setState(() {
                              scheduleList.add(
                                CourseSchedule(
                                  weekday: 1,
                                  period: [1],
                                  weeks: [1],
                                  location: '',
                                ),
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (scheduleList.isEmpty)
                      Text(
                        '暂无时间安排',
                        style: dialogContentSmallStyle,
                      )
                    else
                      ...scheduleList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final schedule = entry.value;
                        return Card(
                          color: mainColorPurple80,
                          margin: EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '时间段 ${index + 1}',
                                      style: dialogContentSmallStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 18, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          scheduleList.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                _buildScheduleField(
                                  label: '星期',
                                  initialValue: schedule.weekday.toString(),
                                  onChanged: (value) {
                                    final weekday = int.tryParse(value);
                                    if (weekday != null && weekday >= 1 && weekday <= 7) {
                                      setState(() {
                                        scheduleList[index] = CourseSchedule(
                                          weekday: weekday,
                                          period: schedule.period,
                                          weeks: schedule.weeks,
                                          location: schedule.location,
                                        );
                                      });
                                    }
                                  },
                                  isNumber: true,
                                ),
                                SizedBox(height: 6),
                                _buildScheduleField(
                                  label: '节次（如：1,2）',
                                  initialValue: schedule.period.join(','),
                                  onChanged: (value) {
                                    final periods = value
                                        .split(',')
                                        .map((e) => int.tryParse(e.trim()))
                                        .where((e) => e != null)
                                        .cast<int>()
                                        .toList();
                                    if (periods.isNotEmpty) {
                                      setState(() {
                                        scheduleList[index] = CourseSchedule(
                                          weekday: schedule.weekday,
                                          period: periods..sort(),
                                          weeks: schedule.weeks,
                                          location: schedule.location,
                                        );
                                      });
                                    }
                                  },
                                ),
                                SizedBox(height: 6),
                                _buildScheduleField(
                                  label: '周次（如：1,2,3-8）',
                                  initialValue: schedule.weeks.join(','),
                                  onChanged: (value) {
                                    final weeks = <int>[];
                                    for (final part in value.split(',')) {
                                      final trimmed = part.trim();
                                      if (trimmed.contains('-')) {
                                        final range = trimmed.split('-');
                                        final start = int.tryParse(range[0]);
                                        final end = int.tryParse(range[1]);
                                        if (start != null && end != null && start <= end) {
                                          for (int i = start; i <= end; i++) {
                                            weeks.add(i);
                                          }
                                        }
                                      } else {
                                        final week = int.tryParse(trimmed);
                                        if (week != null) {
                                          weeks.add(week);
                                        }
                                      }
                                    }
                                    if (weeks.isNotEmpty) {
                                      setState(() {
                                        scheduleList[index] = CourseSchedule(
                                          weekday: schedule.weekday,
                                          period: schedule.period,
                                          weeks: weeks..sort(),
                                          location: schedule.location,
                                        );
                                      });
                                    }
                                  },
                                ),
                                SizedBox(height: 6),
                                _buildScheduleField(
                                  label: '地点',
                                  initialValue: schedule.location,
                                  onChanged: (value) {
                                    setState(() {
                                      scheduleList[index] = CourseSchedule(
                                        weekday: schedule.weekday,
                                        period: schedule.period,
                                        weeks: schedule.weeks,
                                        location: value,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                style: dialogButtonStyle,
                onPressed: () {
                  Navigator.of(context).pop();
                  completer.complete(null);
                },
                child: Text('取消'),
              ),
              TextButton(
                style: dialogButtonStyle,
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    // 解析教师列表
                    final teachers = teachersController.text
                        .split('，')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    // 解析学分
                    double? credit;
                    if (creditController.text.isNotEmpty) {
                      credit = double.tryParse(creditController.text);
                    }

                    // 创建更新后的基本信息
                    final updatedBasicInfo = CourseBasicInfo(
                      subjectName: subjectNameController.text.trim(),
                      courseType: courseTypeController.text.trim(),
                      teachers: teachers,
                      credit: credit,
                      alias: aliasController.text.trim().isEmpty
                          ? null
                          : aliasController.text.trim(),
                      semester: semesterController.text.trim().isEmpty
                          ? null
                          : semesterController.text.trim(),
                    );

                    // 创建新的 CourseData，使用更新后的 schedule
                    final updatedCourseData = CourseData(
                      basicInfo: updatedBasicInfo,
                      schedule: scheduleList,
                    );

                    Navigator.of(context).pop();
                    completer.complete(updatedCourseData);
                  }
                },
                child: Text('确定'),
              ),
            ],
          );
        },
      );
    },
  );

  future.then((_) {
    if (completer.isCompleted) return;
    completer.complete(null);
  });

  return completer.future;
}

// 辅助函数：构建时间安排字段
Widget _buildScheduleField({
  required String label,
  required String initialValue,
  required Function(String) onChanged,
  bool isNumber = false,
}) {
  final controller = TextEditingController(text: initialValue);
  return TextField(
    controller: controller,
    style: dialogContentSmallStyle.copyWith(color: bgColorLight80),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: dialogContentSmallStyle,
      filled: true,
      fillColor: mainColorPurple90,
      border: OutlineInputBorder(
        borderSide: BorderSide(width: 1.0, color: Colors.grey),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
    onChanged: onChanged,
  );
}
