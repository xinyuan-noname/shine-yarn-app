import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/input.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/models/course_data.dart';
import 'package:shine/models/schedule_point_data.dart';
import 'package:shine/models/schedule_reminder_data.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/storage/schedule_point_storage.dart';
import 'package:shine/storage/subject_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/message_utils.dart';
import 'package:shine/utils/to_do_template_utils.dart';

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
  bool isDiy = false,
  CourseData? courseData,
  required Function(String) onJump,

  /// 点击「提醒」后的回调（不传则不显示该按钮）
  VoidCallback? onReminder,

  /// 该课程是否已开启提醒
  bool reminderEnabled = false,
}) async {
  final courseAllName = courseInfo.subjectName.replaceAll("实验", "");
  final teachers = courseInfo.teachers.join("，");
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: mainColorPurple,
        title: Row(
          children: [
            Expanded(child: Text(courseName, style: dialogTitleStyle)),
            if (reminderEnabled)
              Icon(
                Icons.notifications_active,
                size: 18,
                color: deepColorOrange,
              ),
          ],
        ),
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
              SizedBox(height: 11),
              Text("学分：${courseInfo.credit}", style: dialogContentSmallStyle),
            ],
          ),
        ),
        actions: [
          if (onReminder != null)
            TextButton(
              style: dialogButtonStyle,
              onPressed: () {
                Navigator.of(context).pop();
                onReminder();
              },
              child: Text(reminderEnabled ? "提醒设置" : "开启提醒"),
            ),
          if (!isDiy)
            TextButton(
              style: dialogButtonStyle,
              onPressed: () {
                Navigator.of(context).pop();
                onJump(courseName);
              },
              child: Text("查看资源"),
            ),
          if (isDiy && courseData != null)
            TextButton(
              style: dialogButtonStyle,
              onPressed: () async {
                Navigator.of(context).pop();
                final newCourseData = await showCourseDataEditDialog(
                  context: context,
                  courseData: courseData,
                );
                if (newCourseData != null) {
                  await SubjectStorage.removeCurrentDiySubjectInfo(
                    courseAllName,
                  );
                  await SubjectStorage.addCurrentDiySubjectInfo(newCourseData);
                  HomePageRefreshNotifier.refreshSchedule();
                }
              },
              child: Text("编辑课程"),
            ),
        ],
      );
    },
  );
}

const _cnWeekdayShortNames = ['一', '二', '三', '四', '五', '六', '日'];

/// 汇总课程的星期 / 节次 / 地点，用于列表副标题
String _describeCourseSchedule(CourseData courseData) {
  if (courseData.schedule.isEmpty) return '暂无时间安排';
  final sorted = List<CourseSchedule>.from(courseData.schedule)
    ..sort((a, b) {
      final byWeekday = a.weekday.compareTo(b.weekday);
      if (byWeekday != 0) return byWeekday;
      return a.start.compareTo(b.start);
    });
  return sorted
      .map((item) {
        final weekday = item.weekday >= 1 && item.weekday <= 7
            ? '周${_cnWeekdayShortNames[item.weekday - 1]}'
            : '未知星期';
        final period = item.period.isEmpty
            ? '未知节次'
            : '${item.start}-${item.end}节';
        final location = item.location.trim().isEmpty
            ? ''
            : ' ${item.location.trim()}';
        return '$weekday $period$location';
      })
      .join('；');
}

/// 专业任选课选课设置对话框
///
/// [electiveList] 为本学期全部专业任选课（含未选的），[selection] 为本地保存的选课状态，
/// 未记录的科目默认视为已选。返回保存后的选课状态，用户取消时返回 null。
Future<Map<String, bool>?> showElectiveSelectionDialog({
  required BuildContext context,
  required List<CourseData> electiveList,
  required Map<String, bool> selection,
  String? semesterName,
}) async {
  // 当前编辑中的状态，未记录的科目默认「已选」
  final Map<String, bool> current = {
    for (final courseData in electiveList)
      courseData.subjectName: selection[courseData.subjectName] ?? true,
  };
  final completer = Completer<Map<String, bool>?>();

  final future = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final selectedCount = current.values.where((value) => value).length;
          return AlertDialog(
            backgroundColor: mainColorPurple,
            title: Text('专业任选课设置', style: dialogTitleStyle),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${semesterName == null || semesterName.isEmpty ? '当前学期' : semesterName}'
                      '共 ${electiveList.length} 门专业任选课，已选 $selectedCount 门',
                      style: dialogContentSmallStyle.copyWith(
                        color: bgColorLight80,
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(height: 8),
                    // 批量操作
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton(
                          style: dialogButtonStyle,
                          onPressed: () {
                            setState(() {
                              for (final name in current.keys.toList()) {
                                current[name] = true;
                              }
                            });
                          },
                          child: Text('全选'),
                        ),
                        TextButton(
                          style: dialogButtonStyle,
                          onPressed: () {
                            setState(() {
                              for (final name in current.keys.toList()) {
                                current[name] = false;
                              }
                            });
                          },
                          child: Text('全不选'),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    ...electiveList.map((courseData) {
                      final subjectName = courseData.subjectName;
                      final teachers = courseData.teachers.join('，');
                      final credit = courseData.credit;
                      final subtitle = [
                        courseData.courseType,
                        if (teachers.isNotEmpty) teachers,
                        if (credit != null) '$credit学分',
                        _describeCourseSchedule(courseData),
                      ].join(' · ');
                      return CheckboxListTile(
                        value: current[subjectName] ?? true,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: mainColorGreenBlue,
                        checkColor: darkColorPurple,
                        title: Text(
                          courseData.alias ?? subjectName,
                          style: dialogContentStyle.copyWith(
                            color: current[subjectName] == true
                                ? deepColorOrange
                                : bgColorLight60,
                          ),
                        ),
                        subtitle: Text(
                          subtitle,
                          style: dialogContentSmallStyle,
                        ),
                        onChanged: (bool? value) {
                          setState(() {
                            current[subjectName] = value ?? false;
                          });
                        },
                      );
                    }),
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
                  Navigator.of(context).pop();
                  completer.complete(Map<String, bool>.from(current));
                },
                child: Text('保存'),
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

/// 作业事项模板对话框：填科目、作业内容与截止时间，生成标题与内容
///
/// 返回可直接填入事项编辑页的标题与内容，用户取消时返回 null。
Future<({String title, String content})?> showHomeworkTemplateDialog({
  required BuildContext context,
  required List<String> subjectOptions,
}) async {
  final subjectController = TextEditingController();
  final homeworkController = TextEditingController();
  final completer = Completer<({String title, String content})?>();
  DateTime? deadline;
  bool withChaoxingTip = true;

  final future = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          Future<void> pickDeadline() async {
            final now = DateTime.now();
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: deadline ?? now.add(const Duration(days: 7)),
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 5),
              helpText: '选择截止日期',
            );
            if (pickedDate == null || !context.mounted) return;
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: deadline != null
                  ? TimeOfDay(hour: deadline!.hour, minute: deadline!.minute)
                  : const TimeOfDay(hour: 23, minute: 59),
              helpText: '选择截止时间',
            );
            setState(() {
              deadline = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime?.hour ?? 23,
                pickedTime?.minute ?? 59,
              );
            });
          }

          void submit() {
            final subject = subjectController.text.trim();
            final homework = homeworkController.text.trim();
            if (subject.isEmpty && homework.isEmpty) {
              showToast(msg: '请至少填写科目或作业内容');
              return;
            }
            final result = buildHomeworkToDoTemplate(
              subject: subject,
              homework: homework,
              deadline: deadline,
              withChaoxingTip: withChaoxingTip,
            );
            Navigator.of(context).pop();
            completer.complete(result);
          }

          return AlertDialog(
            backgroundColor: mainColorPurple,
            title: Text('作业事项模板', style: dialogTitleStyle),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Input(
                      name: "templateSubject",
                      label: "科目",
                      controller: subjectController,
                      hintStyle: hintStyle,
                      inputStyle: inputStyle,
                      labelStyle: labelStyle,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.grey),
                      ),
                      color: mainColorPurple90,
                    ),
                    if (subjectOptions.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: subjectOptions.map((subject) {
                          return GestureDetector(
                            onTap: () {
                              subjectController.text = subject;
                              setState(() {});
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: mainColorPurple80,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: mainColorGreenBlue60,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                subject,
                                style: dialogContentSmallStyle.copyWith(
                                  color: bgColorLight,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    SizedBox(height: 12),
                    TextField(
                      controller: homeworkController,
                      style: dialogContentSmallStyle.copyWith(
                        color: bgColorLight80,
                      ),
                      maxLines: 3,
                      minLines: 2,
                      decoration: InputDecoration(
                        labelText: '作业内容',
                        labelStyle: dialogContentSmallStyle,
                        hintText: '例如：第三章课后习题 1-10 题',
                        hintStyle: dialogContentSmallStyle,
                        filled: true,
                        fillColor: mainColorPurple90,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 1.0,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deadline == null
                                ? '截止时间：未设置'
                                : '截止时间：${formatToDoDeadline(deadline!)}',
                            style: dialogContentSmallStyle.copyWith(
                              color: bgColorLight80,
                            ),
                          ),
                        ),
                        TextButton(
                          style: dialogButtonStyle,
                          onPressed: pickDeadline,
                          child: Text(deadline == null ? '选择时间' : '修改时间'),
                        ),
                        if (deadline != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                deadline = null;
                              });
                            },
                            icon: Icon(
                              Icons.clear,
                              size: 18,
                              color: bgColorLight60,
                            ),
                            tooltip: '清除截止时间',
                          ),
                      ],
                    ),
                    CheckboxListTile(
                      value: withChaoxingTip,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: mainColorGreenBlue,
                      checkColor: darkColorPurple,
                      title: Text('附上「提交方式：学习通」', style: dialogContentStyle),
                      subtitle: Text(
                        '事项里会出现可点击的学习通标签',
                        style: dialogContentSmallStyle,
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          withChaoxingTip = value ?? false;
                        });
                      },
                    ),
                    SizedBox(height: 4),
                    Text(
                      '生成后会填入标题与内容，可继续修改再保存',
                      style: dialogContentSmallStyle,
                    ),
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
                onPressed: submit,
                child: Text('生成'),
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

/// 日程提醒设置对话框：开关提醒 + 选择提前量（含自定义分钟）
///
/// [previewBuilder] 用来按当前提前量生成「下次提醒」预览文案。
/// 返回保存后的设置，用户取消时返回 null。
Future<ScheduleReminderSetting?> showScheduleReminderDialog({
  required BuildContext context,
  required String courseName,
  required ScheduleReminderSetting setting,
  String? Function(int leadMinutes)? previewBuilder,
}) async {
  final completer = Completer<ScheduleReminderSetting?>();
  var enabled = setting.enabled;
  var leadMinutes = setting.leadMinutes;
  var customMode = !ScheduleReminderSetting.leadMinuteOptions.contains(
    leadMinutes,
  );
  final customController = TextEditingController(
    text: customMode ? leadMinutes.toString() : '',
  );

  final future = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          void applyCustomText() {
            final parsed = int.tryParse(customController.text.trim());
            if (parsed == null) return;
            setState(() {
              leadMinutes = parsed.clamp(0, 24 * 60);
            });
          }

          final preview = enabled ? previewBuilder?.call(leadMinutes) : null;
          return AlertDialog(
            backgroundColor: mainColorPurple,
            title: Text('提醒设置', style: dialogTitleStyle),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '课程：$courseName',
                      style: dialogContentSmallStyle.copyWith(
                        color: bgColorLight80,
                      ),
                    ),
                    SizedBox(height: 8),
                    CheckboxListTile(
                      value: enabled,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: mainColorGreenBlue,
                      checkColor: darkColorPurple,
                      title: Text('开启上课提醒', style: dialogContentStyle),
                      subtitle: Text(
                        '到点前用系统通知提醒你',
                        style: dialogContentSmallStyle,
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          enabled = value ?? false;
                        });
                      },
                    ),
                    if (enabled) ...[
                      SizedBox(height: 4),
                      Text(
                        '提前多久提醒',
                        style: dialogContentStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...ScheduleReminderSetting.leadMinuteOptions.map((
                            minutes,
                          ) {
                            return _buildLeadMinuteChip(
                              label: _leadMinuteLabel(minutes),
                              selected: !customMode && leadMinutes == minutes,
                              onTap: () {
                                setState(() {
                                  customMode = false;
                                  leadMinutes = minutes;
                                });
                              },
                            );
                          }),
                          _buildLeadMinuteChip(
                            label: '自定义',
                            selected: customMode,
                            onTap: () {
                              setState(() {
                                customMode = true;
                              });
                            },
                          ),
                        ],
                      ),
                      if (customMode) ...[
                        SizedBox(height: 8),
                        TextField(
                          controller: customController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: dialogContentSmallStyle.copyWith(
                            color: bgColorLight80,
                          ),
                          onChanged: (_) => applyCustomText(),
                          decoration: InputDecoration(
                            labelText: '提前分钟数（0-1440）',
                            labelStyle: dialogContentSmallStyle,
                            filled: true,
                            fillColor: mainColorPurple90,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 1.0,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 10),
                      Text(
                        '当前：${ScheduleReminderSetting(enabled: true, leadMinutes: leadMinutes).leadText}',
                        style: dialogContentSmallStyle.copyWith(
                          color: deepColorOrange,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        preview ?? '未来 7 天没有该课程的课次，暂时不会提醒',
                        style: dialogContentSmallStyle,
                      ),
                    ],
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
                  if (customMode) applyCustomText();
                  Navigator.of(context).pop();
                  completer.complete(
                    ScheduleReminderSetting(
                      enabled: enabled,
                      leadMinutes: leadMinutes,
                    ),
                  );
                },
                child: Text('保存'),
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

String _leadMinuteLabel(int minutes) => formatMinutesText(minutes);

Widget _buildLeadMinuteChip({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: selected ? mainColorGreenBlue : mainColorPurple80,
        border: Border.all(
          color: selected ? mainColorGreenBlue : mainColorGreenBlue60,
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: dialogContentSmallStyle.copyWith(
          color: selected ? darkColorPurple : bgColorLight,
        ),
      ),
    ),
  );
}

/// 统一的日程提醒管理：一个弹窗里开关所有课程的提醒、设置提前量
///
/// [previewBuilder] 用来按提前量生成「下次提醒」预览文案。
/// 返回保存后的完整设置（含没有列出的历史条目），用户取消时返回 null。
Future<Map<String, ScheduleReminderSetting>?>
showScheduleReminderManagerDialog({
  required BuildContext context,
  required List<CourseData> courseList,
  required Map<String, ScheduleReminderSetting> settings,
  String? Function(String subjectName, int leadMinutes)? previewBuilder,

  /// 进入弹窗时已经排期出去的提醒条数
  int? scheduledCount,

  /// 系统通知权限是否可用（关掉时提醒送不到）
  bool notificationsAllowed = true,

  /// 是否已拿到精确闹钟权限（没有时提醒可能延迟几分钟）
  bool exactAlarmAllowed = true,

  /// 点击「发送测试提醒」时调用，返回是否发送成功
  Future<bool> Function()? onSendTestNotification,

  /// 点击「1 分钟后提醒」时调用（走真正的定时排期链路），返回是否排期成功
  Future<bool> Function()? onScheduleDelayedTest,
}) async {
  final Map<String, ScheduleReminderSetting> current = {
    for (final course in courseList)
      course.subjectName:
          settings[course.subjectName] ?? ScheduleReminderSetting.disabled,
  };
  // 统一提前量：优先沿用已开启课程里最常见的那个
  var defaultLeadMinutes = _mostUsedLeadMinutes(current.values);
  final completer = Completer<Map<String, ScheduleReminderSetting>?>();

  final future = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final enabledCount = current.values.where((s) => s.enabled).length;
          return AlertDialog(
            backgroundColor: mainColorPurple,
            title: Text('日程提醒', style: dialogTitleStyle),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '共 ${courseList.length} 门课程，已开启 $enabledCount 门'
                      '${scheduledCount == null ? '' : '，已排期 $scheduledCount 条提醒'}',
                      style: dialogContentSmallStyle.copyWith(
                        color: bgColorLight80,
                      ),
                    ),
                    if (!notificationsAllowed)
                      _buildReminderWarning(
                        '系统通知权限未开启，提醒发不出去：请在系统设置里允许「闪纺」发送通知',
                      ),
                    if (!exactAlarmAllowed)
                      _buildReminderWarning('未获得「闹钟和提醒」权限，提醒可能延迟几分钟'),
                    SizedBox(height: 8),
                    Text(
                      '新开启课程的提前量',
                      style: dialogContentStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...ScheduleReminderSetting.leadMinuteOptions.map((
                          minutes,
                        ) {
                          return _buildLeadMinuteChip(
                            label: _leadMinuteLabel(minutes),
                            selected:
                                defaultLeadMinutes == minutes &&
                                ScheduleReminderSetting.leadMinuteOptions
                                    .contains(defaultLeadMinutes),
                            onTap: () {
                              setState(() {
                                defaultLeadMinutes = minutes;
                              });
                            },
                          );
                        }),
                        _buildLeadMinuteChip(
                          label: '自定义',
                          selected: !ScheduleReminderSetting.leadMinuteOptions
                              .contains(defaultLeadMinutes),
                          onTap: () async {
                            final minutes =
                                await showScheduleReminderLeadPicker(
                                  context: context,
                                  initialLeadMinutes: defaultLeadMinutes,
                                );
                            if (minutes == null) return;
                            setState(() {
                              defaultLeadMinutes = minutes;
                            });
                          },
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton(
                          style: dialogButtonStyle,
                          onPressed: () {
                            setState(() {
                              for (final name in current.keys.toList()) {
                                current[name] = ScheduleReminderSetting(
                                  enabled: true,
                                  leadMinutes: defaultLeadMinutes,
                                );
                              }
                            });
                          },
                          child: Text('全部开启'),
                        ),
                        TextButton(
                          style: dialogButtonStyle,
                          onPressed: () {
                            setState(() {
                              for (final name in current.keys.toList()) {
                                final setting = current[name];
                                if (setting == null) continue;
                                current[name] = setting.copyWith(
                                  enabled: false,
                                );
                              }
                            });
                          },
                          child: Text('全部关闭'),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    ...courseList.map((course) {
                      final subjectName = course.subjectName;
                      final setting =
                          current[subjectName] ??
                          ScheduleReminderSetting.disabled;
                      final preview = setting.enabled
                          ? previewBuilder?.call(
                              subjectName,
                              setting.leadMinutes,
                            )
                          : null;
                      return SwitchListTile(
                        value: setting.enabled,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: mainColorGreenBlue,
                        secondary: IconButton(
                          tooltip: '单独设置这门课的提前量',
                          onPressed: setting.enabled
                              ? () async {
                                  final minutes =
                                      await showScheduleReminderLeadPicker(
                                        context: context,
                                        initialLeadMinutes: setting.leadMinutes,
                                      );
                                  if (minutes == null) return;
                                  setState(() {
                                    current[subjectName] = setting.copyWith(
                                      leadMinutes: minutes,
                                    );
                                  });
                                }
                              : null,
                          icon: Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: setting.enabled
                                ? bgColorLight80
                                : bgColorLight60,
                          ),
                        ),
                        title: Text(
                          course.alias ?? subjectName,
                          style: dialogContentStyle,
                        ),
                        subtitle: Text(
                          setting.enabled
                              ? '${setting.leadText}'
                                    '${preview == null ? ' · 未来 7 天没有这节课' : ' · $preview'}'
                              : '未开启提醒',
                          style: dialogContentSmallStyle,
                        ),
                        onChanged: (bool? value) {
                          final enabled = value ?? false;
                          setState(() {
                            current[subjectName] = ScheduleReminderSetting(
                              enabled: enabled,
                              leadMinutes: setting.enabled
                                  ? setting.leadMinutes
                                  : defaultLeadMinutes,
                            );
                          });
                        },
                      );
                    }),
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
                  Navigator.of(context).pop();
                  completer.complete({...settings, ...current});
                },
                child: Text('保存'),
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

/// 单独的提前量选择弹窗（管理列表里点计时器图标时用）
Future<int?> showScheduleReminderLeadPicker({
  required BuildContext context,
  required int initialLeadMinutes,
}) async {
  final completer = Completer<int?>();
  var leadMinutes = initialLeadMinutes;
  var customMode = !ScheduleReminderSetting.leadMinuteOptions.contains(
    initialLeadMinutes,
  );
  final customController = TextEditingController(
    text: customMode ? initialLeadMinutes.toString() : '',
  );

  final future = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          void applyCustomText() {
            final parsed = int.tryParse(customController.text.trim());
            if (parsed == null) return;
            leadMinutes = parsed.clamp(0, 24 * 60);
          }

          return AlertDialog(
            backgroundColor: mainColorPurple,
            title: Text('提前多久提醒', style: dialogTitleStyle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...ScheduleReminderSetting.leadMinuteOptions.map((minutes) {
                      return _buildLeadMinuteChip(
                        label: _leadMinuteLabel(minutes),
                        selected: !customMode && leadMinutes == minutes,
                        onTap: () {
                          setState(() {
                            customMode = false;
                            leadMinutes = minutes;
                          });
                        },
                      );
                    }),
                    _buildLeadMinuteChip(
                      label: '自定义',
                      selected: customMode,
                      onTap: () {
                        setState(() {
                          customMode = true;
                        });
                      },
                    ),
                  ],
                ),
                if (customMode) ...[
                  SizedBox(height: 8),
                  TextField(
                    controller: customController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: dialogContentSmallStyle.copyWith(
                      color: bgColorLight80,
                    ),
                    onChanged: (_) => applyCustomText(),
                    decoration: InputDecoration(
                      labelText: '提前分钟数（0-1440）',
                      labelStyle: dialogContentSmallStyle,
                      filled: true,
                      fillColor: mainColorPurple90,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ],
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
                  if (customMode) applyCustomText();
                  Navigator.of(context).pop();
                  completer.complete(leadMinutes);
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

/// 提醒相关的警告条（权限不足时提示用户去哪里开）
Widget _buildReminderWarning(String text) {
  return Container(
    margin: EdgeInsets.only(top: 6),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: mainColorRed20,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: mainColorRed50, width: 0.8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_rounded, size: 16, color: mainColorRed),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: dialogContentSmallStyle.copyWith(color: bgColorLight),
          ),
        ),
      ],
    ),
  );
}

/// 已开启课程里最常见的提前量
int _mostUsedLeadMinutes(Iterable<ScheduleReminderSetting> settings) {
  final counts = <int, int>{};
  for (final setting in settings) {
    if (!setting.enabled) continue;
    counts[setting.leadMinutes] = (counts[setting.leadMinutes] ?? 0) + 1;
  }
  if (counts.isEmpty) return ScheduleReminderSetting.defaultLeadMinutes;
  var best = ScheduleReminderSetting.defaultLeadMinutes;
  var bestCount = 0;
  counts.forEach((minutes, count) {
    if (count > bestCount) {
      best = minutes;
      bestCount = count;
    }
  });
  return best;
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
    items: groupStorageKeyLabelList,
    initialValue: initialValue,
  );
}

Future<SchedulePointData?> showSchedulePointDialog({
  required BuildContext context,
}) async {
  // 获取现有数据或初始化空数据
  SchedulePointData? existingData =
      await SchedulePointStorage.getSchedulePointData();

  // 初始化7天的评分规则（如果不存在）
  final List<SchedulePointRule> weekRules =
      existingData?.weekRules.toList() ??
      List.generate(
        7,
        (index) => SchedulePointRule(
          weekday: index + 1,
          bonusItems: [],
          deductionItems: [],
        ),
      );

  final completer = Completer<SchedulePointData?>();

  const weekNames = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

  final future = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: mainColorPurple,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('评分规则管理', style: dialogTitleStyle),
                IconButton(
                  icon: Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                  onPressed: () async {
                    final confirmed = await showConfirmDialog(
                      context: context,
                      title: '清空所有评分规则',
                      content: '确定要清空所有星期的评分规则吗？此操作不可恢复！',
                    );
                    if (confirmed) {
                      setState(() {
                        for (int i = 0; i < 7; i++) {
                          weekRules[i] = SchedulePointRule(
                            weekday: i + 1,
                            bonusItems: [],
                            deductionItems: [],
                          );
                        }
                      });
                      showToast(msg: '已清空所有评分规则');
                    }
                  },
                  tooltip: '清空所有评分规则',
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(7, (weekdayIndex) {
                      final rule = weekRules[weekdayIndex];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: BoxBorder.all(color: mainColorGreenBlue),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 5),
                        padding: EdgeInsets.all(3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    margin: EdgeInsets.only(
                                      top: weekdayIndex > 0 ? 16 : 0,
                                      bottom: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: mainColorPurple70,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      weekNames[weekdayIndex],
                                      style: dialogContentSmallStyle.copyWith(
                                        fontSize: 20,
                                        color: bgColorLight,
                                      ),
                                    ),
                                  ),
                                ),
                                // 复制按钮
                                IconButton(
                                  icon: Icon(
                                    Icons.content_copy,
                                    size: 18,
                                    color: mainColorGreenBlue,
                                  ),
                                  onPressed: () async {
                                    await _showCopyToWeekDialog(
                                      context: context,
                                      setState: setState,
                                      sourceWeekIndex: weekdayIndex,
                                      weekRules: weekRules,
                                      weekNames: weekNames,
                                    );
                                  },
                                  tooltip: '复制到其它星期',
                                ),
                                // 删除按钮
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirmed = await showConfirmDialog(
                                      context: context,
                                      title: '删除${weekNames[weekdayIndex]}评分规则',
                                      content:
                                          '确定要删除${weekNames[weekdayIndex]}的所有评分规则吗？',
                                    );
                                    if (confirmed) {
                                      setState(() {
                                        weekRules[weekdayIndex] =
                                            SchedulePointRule(
                                              weekday: weekdayIndex + 1,
                                              bonusItems: [],
                                              deductionItems: [],
                                            );
                                      });
                                      showToast(
                                        msg:
                                            '已删除${weekNames[weekdayIndex]}的评分规则',
                                      );
                                    }
                                  },
                                  tooltip: '删除${weekNames[weekdayIndex]}的评分规则',
                                ),
                              ],
                            ),
                            // 加分项
                            _buildSection(
                              title: '加分项',
                              items: rule.bonusItems,
                              isBonus: true,
                              onAdd: () => _showAddItemDialog(
                                context: context,
                                setState: setState,
                                items: rule.bonusItems,
                                isBonus: true,
                                commonItems: [],
                                weekRules: weekRules,
                                weekdayIndex: weekdayIndex,
                              ),
                              onDelete: (index) {
                                setState(() {
                                  weekRules[weekdayIndex] = rule.copyWith(
                                    bonusItems: List.from(rule.bonusItems)
                                      ..removeAt(index),
                                  );
                                });
                              },
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) {
                                    newIndex -= 1;
                                  }
                                  final items = List<SchedulePointItem>.from(
                                    rule.bonusItems,
                                  );
                                  final item = items.removeAt(oldIndex);
                                  items.insert(newIndex, item);
                                  weekRules[weekdayIndex] = rule.copyWith(
                                    bonusItems: items,
                                  );
                                });
                              },
                            ),
                            SizedBox(height: 8),
                            // 扣分项
                            _buildSection(
                              title: '扣分项',
                              items: rule.deductionItems,
                              isBonus: false,
                              onAdd: () => _showAddItemDialog(
                                context: context,
                                setState: setState,
                                items: rule.deductionItems,
                                isBonus: false,
                                commonItems: [],
                                weekRules: weekRules,
                                weekdayIndex: weekdayIndex,
                              ),
                              onDelete: (index) {
                                setState(() {
                                  weekRules[weekdayIndex] = rule.copyWith(
                                    deductionItems: List.from(
                                      rule.deductionItems,
                                    )..removeAt(index),
                                  );
                                });
                              },
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) {
                                    newIndex -= 1;
                                  }
                                  final items = List<SchedulePointItem>.from(
                                    rule.deductionItems,
                                  );
                                  final item = items.removeAt(oldIndex);
                                  items.insert(newIndex, item);
                                  weekRules[weekdayIndex] = rule.copyWith(
                                    deductionItems: items,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
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
                onPressed: () async {
                  final data = SchedulePointData(weekRules: weekRules);
                  await SchedulePointStorage.saveSchedulePointData(data);
                  Navigator.of(context).pop();
                  completer.complete(data);
                },
                child: Text('保存'),
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

/// 构建评分项区域
Widget _buildSection({
  required String title,
  required List<SchedulePointItem> items,
  required bool isBonus,
  required VoidCallback onAdd,
  required Function(int) onDelete,
  required Function(int, int) onReorder,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: dialogContentStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 20, color: bgColorLight80),
            onPressed: onAdd,
            tooltip: '添加评分项',
          ),
        ],
      ),
      SizedBox(height: 8),
      if (items.isEmpty)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('暂无评分项', style: dialogContentSmallStyle),
        )
      else
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: items.length,
          onReorder: onReorder,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              key: ValueKey(item.id),
              color: mainColorPurple80,
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.drag_indicator, color: bgColorLight60),
                title: Text(
                  item.name,
                  style: dialogContentSmallStyle.copyWith(
                    color: bgColorLight80,
                  ),
                ),
                subtitle: Text(
                  isBonus
                      ? '权重: ${item.weight.toStringAsFixed(1)}'
                      : '占比: ${item.weight.toStringAsFixed(1)}%',
                  style: dialogContentSmallStyle.copyWith(
                    color: bgColorLight60,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => onDelete(index),
                ),
              ),
            );
          },
        ),
    ],
  );
}

/// 显示添加评分项对话框
void _showAddItemDialog({
  required BuildContext context,
  required StateSetter setState,
  required List<SchedulePointItem> items,
  required bool isBonus,
  required List<String> commonItems,
  required List<SchedulePointRule> weekRules,
  required int weekdayIndex,
}) {
  final nameController = TextEditingController();
  final weightController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  List<String> filteredSuggestions = [];
  bool showSuggestions = false;
  // 用于存储选中的星期（默认包含当前星期）
  Set<int> selectedWeekdays = {weekdayIndex};

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter dialogSetState) {
          return AlertDialog(
            backgroundColor: mainColorPurple,
            title: Text(isBonus ? '添加加分项' : '添加扣分项', style: dialogTitleStyle),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 名称输入框（带自动补全）
                  TextFormField(
                    controller: nameController,
                    style: dialogContentSmallStyle.copyWith(
                      color: bgColorLight80,
                    ),
                    decoration: InputDecoration(
                      labelText: '评分项名称',
                      labelStyle: dialogContentSmallStyle,
                      filled: true,
                      fillColor: mainColorPurple90,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.grey),
                      ),
                    ),
                    onChanged: (value) {
                      dialogSetState(() {
                        if (value.isEmpty) {
                          showSuggestions = false;
                          filteredSuggestions = [];
                        } else {
                          filteredSuggestions = commonItems
                              .where((item) => item.contains(value))
                              .toList();
                          showSuggestions = filteredSuggestions.isNotEmpty;
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入评分项名称';
                      }
                      return null;
                    },
                  ),
                  // 自动补全下拉列表
                  if (showSuggestions)
                    Container(
                      constraints: BoxConstraints(maxHeight: 150),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredSuggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              filteredSuggestions[index],
                              style: dialogContentSmallStyle,
                            ),
                            onTap: () {
                              nameController.text = filteredSuggestions[index];
                              dialogSetState(() {
                                showSuggestions = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 12),
                  // 权重/占比输入框
                  TextFormField(
                    controller: weightController,
                    style: dialogContentSmallStyle.copyWith(
                      color: bgColorLight80,
                    ),
                    decoration: InputDecoration(
                      labelText: isBonus ? '权重' : '占比(%)',
                      labelStyle: dialogContentSmallStyle,
                      filled: true,
                      fillColor: mainColorPurple90,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.grey),
                      ),
                      suffixText: isBonus ? '' : '%',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,1}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isBonus ? '请输入权重' : '请输入占比';
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight <= 0) {
                        return '请输入有效的数值';
                      }
                      if (!isBonus && weight > 100) {
                        return '占比不能超过100%';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: dialogButtonStyle,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('取消'),
              ),
              TextButton(
                style: dialogButtonStyle,
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final name = nameController.text.trim();
                    final weight = double.parse(weightController.text.trim());

                    // 创建新的评分项
                    final newItem = SchedulePointItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      isBonus: isBonus,
                      weight: weight,
                    );

                    // 添加到选中的星期
                    setState(() {
                      for (final targetWeekdayIndex in selectedWeekdays) {
                        final targetRule = weekRules[targetWeekdayIndex];
                        if (isBonus) {
                          // 检查是否已存在同名项
                          if (!targetRule.bonusItems.any(
                            (existing) => existing.name == name,
                          )) {
                            weekRules[targetWeekdayIndex] = targetRule.copyWith(
                              bonusItems: List.from(targetRule.bonusItems)
                                ..add(newItem),
                            );
                          }
                        } else {
                          // 检查是否已存在同名项
                          if (!targetRule.deductionItems.any(
                            (existing) => existing.name == name,
                          )) {
                            weekRules[targetWeekdayIndex] = targetRule.copyWith(
                              deductionItems: List.from(
                                targetRule.deductionItems,
                              )..add(newItem),
                            );
                          }
                        }
                      }
                    });

                    final targetNames = selectedWeekdays
                        .map(
                          (i) => [
                            '星期一',
                            '星期二',
                            '星期三',
                            '星期四',
                            '星期五',
                            '星期六',
                            '星期日',
                          ][i],
                        )
                        .join('、');
                    showToast(msg: '已添加到 $targetNames');

                    Navigator.of(context).pop();
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

  // 用于存储每个时间安排的控制器
  final weekdayControllers = <TextEditingController>[];
  final periodControllers = <TextEditingController>[];
  final weeksControllers = <TextEditingController>[];
  final locationControllers = <TextEditingController>[];

  // 初始化控制器
  for (final schedule in scheduleList) {
    weekdayControllers.add(
      TextEditingController(text: schedule.weekday.toString()),
    );
    periodControllers.add(
      TextEditingController(text: schedule.period.join(',')),
    );
    weeksControllers.add(TextEditingController(text: schedule.weeks.join(',')));
    locationControllers.add(TextEditingController(text: schedule.location));
  }

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
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                          icon: Icon(
                            Icons.add,
                            size: 18,
                            color: bgColorLight80,
                          ),
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
                              weekdayControllers.add(
                                TextEditingController(text: '1'),
                              );
                              periodControllers.add(
                                TextEditingController(text: '1'),
                              );
                              weeksControllers.add(
                                TextEditingController(text: '1'),
                              );
                              locationControllers.add(
                                TextEditingController(text: ''),
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (scheduleList.isEmpty)
                      Text('暂无时间安排', style: dialogContentSmallStyle)
                    else
                      ...scheduleList.asMap().entries.map((entry) {
                        final index = entry.key;
                        return Card(
                          color: mainColorPurple80,
                          margin: EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '时间段 ${index + 1}',
                                      style: dialogContentSmallStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          scheduleList.removeAt(index);
                                          weekdayControllers
                                              .removeAt(index)
                                              .dispose();
                                          periodControllers
                                              .removeAt(index)
                                              .dispose();
                                          weeksControllers
                                              .removeAt(index)
                                              .dispose();
                                          locationControllers
                                              .removeAt(index)
                                              .dispose();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                _buildScheduleField(
                                  label: '星期',
                                  controller: weekdayControllers[index],
                                  isNumber: true,
                                ),
                                SizedBox(height: 6),
                                _buildScheduleField(
                                  label: '节次（如：1,2）',
                                  controller: periodControllers[index],
                                ),
                                SizedBox(height: 6),
                                _buildScheduleField(
                                  label: '周次（如：1,2,3-8）',
                                  controller: weeksControllers[index],
                                ),
                                SizedBox(height: 6),
                                _buildScheduleField(
                                  label: '地点',
                                  controller: locationControllers[index],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                style: dialogButtonStyle,
                onPressed: () async {
                  Navigator.of(context).pop();
                  completer.complete(null);
                },
                child: Text('取消'),
              ),
              TextButton(
                style: dialogButtonStyle,
                onPressed: () async {
                  await Future.delayed(Duration(milliseconds: 300));
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

                    // 解析时间安排
                    final parsedSchedules = <CourseSchedule>[];
                    bool hasError = false;

                    for (int i = 0; i < scheduleList.length; i++) {
                      final weekday = int.tryParse(
                        weekdayControllers[i].text.trim(),
                      );
                      if (weekday == null || weekday < 1 || weekday > 7) {
                        hasError = true;
                        break;
                      }

                      final periods = periodControllers[i].text
                          .split(',')
                          .map((e) => int.tryParse(e.trim()))
                          .where((e) => e != null && e >= 0 && e <= 10)
                          .cast<int>()
                          .toList();
                      if (periods.isEmpty) {
                        hasError = true;
                        break;
                      }
                      periods.sort();

                      final weeks = <int>[];
                      for (final part in weeksControllers[i].text.split(',')) {
                        final trimmed = part.trim();
                        if (trimmed.contains('-')) {
                          final range = trimmed.split('-');
                          final start = int.tryParse(range[0]);
                          final end = int.tryParse(range[1]);
                          if (start != null && end != null && start <= end) {
                            for (int j = start; j <= end; j++) {
                              weeks.add(j);
                            }
                          }
                        } else {
                          final week = int.tryParse(trimmed);
                          if (week != null) {
                            weeks.add(week);
                          }
                        }
                      }
                      if (weeks.isEmpty) {
                        hasError = true;
                        break;
                      }
                      weeks.sort();

                      parsedSchedules.add(
                        CourseSchedule(
                          weekday: weekday,
                          period: periods,
                          weeks: weeks,
                          location: locationControllers[i].text.trim(),
                        ),
                      );
                    }

                    if (hasError) return;

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

                    // 创建新的 CourseData
                    final updatedCourseData = CourseData(
                      basicInfo: updatedBasicInfo,
                      schedule: parsedSchedules,
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

// 辅助函数：构建带防抖的时间安排字段
Widget _buildScheduleField({
  required String label,
  required TextEditingController controller,
  bool isNumber = false,
}) {
  // 将光标移动到文本末尾
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (controller.text.isNotEmpty) {
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }
  });

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
  );
}

/// 显示每日评分对话框（用于切换完成状态和查看得分）
Future<bool?> showDailySchedulePointDialog({
  required BuildContext context,
  required DateTime date, // 日期
  required int weekday, // 星期几 (1-7)
  double baseScore = 10.0, // 基准分，默认10分
}) async {
  // 获取评分规则和数据
  SchedulePointData? existingData =
      await SchedulePointStorage.getSchedulePointData();

  if (existingData == null || weekday < 1 || weekday > 7) {
    showToast(msg: "未找到评分规则");
    return null;
  }

  final rule = existingData.weekRules[weekday - 1];
  // 使用日期字符串作为Map的key（格式: YYYY-MM-DD）
  final dateKey =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final dailyRecord =
      existingData.dailyRecords[dateKey] ?? DailySchedulePoint();

  // 复制完成状态Map以便修改
  Map<String, bool> itemCompletionStatus = Map<String, bool>.from(
    dailyRecord.itemCompletionStatus,
  );
  double score = dailyRecord.score;

  const weekNames = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

  final completer = Completer<bool?>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: mainColorPurple,
            title: Text(
              '${weekNames[weekday - 1]} 评分',
              style: dialogTitleStyle,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 得分显示
                    Card(
                      color: mainColorPurple80,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '总得分',
                              style: dialogContentStyle.copyWith(
                                color: bgColorLight80,
                              ),
                            ),
                            Text(
                              score.toStringAsFixed(1),
                              style: dialogContentStyle.copyWith(
                                color: mainColorGreenBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // 加分项列表
                    if (rule.bonusItems.isNotEmpty) ...[
                      Text(
                        '加分项',
                        style: dialogContentStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: bgColorLight80,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...rule.bonusItems.map(
                        (item) => _buildPointItemCard(
                          item: item,
                          isBonus: true,
                          isCompleted: itemCompletionStatus[item.id] ?? false,
                          onToggle: () {
                            setState(() {
                              itemCompletionStatus[item.id] =
                                  !(itemCompletionStatus[item.id] ?? false);
                              // 重新计算得分
                              score = _calculateScore(
                                rule,
                                itemCompletionStatus,
                                baseScore,
                              );
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 12),
                    ],
                    // 扣分项列表
                    if (rule.deductionItems.isNotEmpty) ...[
                      Text(
                        '扣分项',
                        style: dialogContentStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: bgColorLight80,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...rule.deductionItems.map(
                        (item) => _buildPointItemCard(
                          item: item,
                          isBonus: false,
                          isCompleted: itemCompletionStatus[item.id] ?? false,
                          onToggle: () {
                            setState(() {
                              itemCompletionStatus[item.id] =
                                  !(itemCompletionStatus[item.id] ?? false);
                              // 重新计算得分
                              score = _calculateScore(
                                rule,
                                itemCompletionStatus,
                                baseScore,
                              );
                            });
                          },
                        ),
                      ),
                    ],
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
                onPressed: () async {
                  // 保存评分数据
                  final updatedData = existingData.copyWith(
                    dailyRecords:
                        Map<String, DailySchedulePoint>.from(
                            existingData.dailyRecords,
                          )
                          ..[dateKey] = DailySchedulePoint(
                            itemCompletionStatus: itemCompletionStatus,
                            score: score,
                          ),
                  );
                  await SchedulePointStorage.saveSchedulePointData(updatedData);
                  Navigator.of(context).pop();
                  completer.complete(true);
                },
                child: Text('保存'),
              ),
            ],
          );
        },
      );
    },
  );

  return completer.future;
}

/// 计算得分（基准分可配置，加分项按权重比例分配基准分，扣分项按百分比扣除）
double _calculateScore(
  SchedulePointRule rule,
  Map<String, bool> itemCompletionStatus,
  double baseScore,
) {
  double totalScore = 0.0; // 初始为0分

  // 计算加分项总权重
  double totalBonusWeight = rule.bonusItems.fold(
    0.0,
    (sum, item) => sum + item.weight,
  );

  // 计算加分项得分（按权重比例分配基准分）
  if (totalBonusWeight > 0) {
    for (final item in rule.bonusItems) {
      if (itemCompletionStatus[item.id] ?? false) {
        // 该项得分 = (该项权重 / 总权重) × 基准分
        totalScore += (item.weight / totalBonusWeight) * baseScore;
      }
    }
  }

  // 计算扣分项（按基准分的百分比扣除）
  for (final item in rule.deductionItems) {
    if (itemCompletionStatus[item.id] ?? false) {
      // 扣分 = 基准分 × (占比 / 100)
      totalScore -= baseScore * (item.weight / 100.0);
    }
  }

  return totalScore;
}

/// 构建评分项卡片
Widget _buildPointItemCard({
  required SchedulePointItem item,
  required bool isBonus,
  required bool isCompleted,
  required VoidCallback onToggle,
}) {
  return GestureDetector(
    onTap: onToggle,
    child: Card(
      color: isCompleted
          ? (isBonus ? mainColorGreenBlue30 : mainColorRed50)
          : mainColorPurple90,
      margin: EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: isCompleted
                  ? (isBonus ? mainColorGreenBlue : Colors.red)
                  : bgColorLight60,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: dialogContentSmallStyle.copyWith(
                      color: bgColorLight80,
                      decoration: isCompleted && !isBonus
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    isBonus
                        ? '权重: ${item.weight.toStringAsFixed(1)}'
                        : '占比: ${item.weight.toStringAsFixed(1)}%',
                    style: dialogContentSmallStyle.copyWith(
                      color: bgColorLight60,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isBonus ? Icons.add_circle : Icons.remove_circle,
              color: isBonus ? mainColorGreenBlue : Colors.red,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}

/// 显示复制到其它星期的对话框
Future<void> _showCopyToWeekDialog({
  required BuildContext context,
  required StateSetter setState,
  required int sourceWeekIndex,
  required List<SchedulePointRule> weekRules,
  required List<String> weekNames,
}) async {
  final sourceRule = weekRules[sourceWeekIndex];

  // 检查源星期是否有规则
  if (sourceRule.bonusItems.isEmpty && sourceRule.deductionItems.isEmpty) {
    showToast(msg: '${weekNames[sourceWeekIndex]}没有评分规则，无法复制');
    return;
  }

  // 选择目标星期（包含当前星期）
  final List<int> targetOptions = List.generate(7, (i) => i);
  // 默认包含当前编辑的星期索引
  final Set<int> selectedTargets = {sourceWeekIndex};

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter dialogSetState) {
          return AlertDialog(
            backgroundColor: mainColorPurple,
            title: Text('复制到其它星期', style: dialogTitleStyle),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '从 ${weekNames[sourceWeekIndex]} 复制到：',
                    style: dialogContentSmallStyle.copyWith(
                      color: bgColorLight80,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...targetOptions.map((targetIndex) {
                    return CheckboxListTile(
                      value: selectedTargets.contains(targetIndex),
                      title: Text(
                        weekNames[targetIndex],
                        style: dialogContentSmallStyle.copyWith(
                          color: bgColorLight80,
                        ),
                      ),
                      subtitle: Text(
                        weekRules[targetIndex].bonusItems.isEmpty &&
                                weekRules[targetIndex].deductionItems.isEmpty
                            ? '（空）'
                            : '（已有 ${weekRules[targetIndex].bonusItems.length} 个加分项，${weekRules[targetIndex].deductionItems.length} 个扣分项）',
                        style: dialogContentSmallStyle.copyWith(
                          color: bgColorLight60,
                        ),
                      ),
                      activeColor: mainColorGreenBlue,
                      onChanged: (bool? value) {
                        dialogSetState(() {
                          if (value == true) {
                            selectedTargets.add(targetIndex);
                          } else {
                            selectedTargets.remove(targetIndex);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: dialogButtonStyle,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('取消'),
              ),
              TextButton(
                style: dialogButtonStyle,
                onPressed: () {
                  if (selectedTargets.isEmpty) {
                    showToast(msg: '请至少选择一个目标星期');
                    return;
                  }

                  // 执行复制合并操作
                  setState(() {
                    for (final targetIndex in selectedTargets) {
                      final targetRule = weekRules[targetIndex];

                      // 合并加分项（避免重复）
                      final mergedBonusItems = List<SchedulePointItem>.from(
                        targetRule.bonusItems,
                      );
                      for (final item in sourceRule.bonusItems) {
                        // 通过名称判断是否已存在
                        if (!mergedBonusItems.any(
                          (existing) => existing.name == item.name,
                        )) {
                          mergedBonusItems.add(item);
                        }
                      }

                      // 合并扣分项（避免重复）
                      final mergedDeductionItems = List<SchedulePointItem>.from(
                        targetRule.deductionItems,
                      );
                      for (final item in sourceRule.deductionItems) {
                        // 通过名称判断是否已存在
                        if (!mergedDeductionItems.any(
                          (existing) => existing.name == item.name,
                        )) {
                          mergedDeductionItems.add(item);
                        }
                      }

                      // 更新目标星期的规则
                      weekRules[targetIndex] = SchedulePointRule(
                        weekday: targetIndex + 1,
                        bonusItems: mergedBonusItems,
                        deductionItems: mergedDeductionItems,
                      );
                    }
                  });

                  final targetNames = selectedTargets
                      .map((i) => weekNames[i])
                      .join('、');
                  showToast(msg: '已复制到 $targetNames');

                  Navigator.of(context).pop();
                },
                child: Text('确定复制'),
              ),
            ],
          );
        },
      );
    },
  );
}
