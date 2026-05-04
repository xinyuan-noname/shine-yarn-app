import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/input.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/models/course_data.dart';
import 'package:shine/models/schedule_point_data.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/storage/schedule_point_storage.dart';
import 'package:shine/storage/subject_storage.dart';
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
  bool isDiy = false,
  CourseData? courseData,
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
              SizedBox(height: 11),
              Text("学分：${courseInfo.credit}", style: dialogContentSmallStyle),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: dialogButtonStyle,
            onPressed: onYes ?? () => Navigator.of(context).pop(),
            child: Text("关闭"),
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
}) {
  final nameController = TextEditingController();
  final weightController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  List<String> filteredSuggestions = [];
  bool showSuggestions = false;

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

                    setState(() {
                      items.add(
                        SchedulePointItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          isBonus: isBonus,
                          weight: weight,
                        ),
                      );
                    });

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
  required String dateKey, // 日期key，格式: "YYYY-MM-DD"
  required int weekday, // 星期几 (1-7)
}) async {
  // 获取评分规则和数据
  SchedulePointData? existingData =
      await SchedulePointStorage.getSchedulePointData();

  if (existingData == null || weekday < 1 || weekday > 7) {
    showToast(msg: "未找到评分规则");
    return null;
  }

  final rule = existingData.weekRules[weekday - 1];
  final dailyRecord =
      existingData.dailyRecords[dateKey] ?? DailySchedulePoint();

  bool isCompleted = dailyRecord.isCompleted;
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
                    // 完成状态切换
                    Card(
                      color: isCompleted
                          ? mainColorGreenBlue30
                          : mainColorPurple80,
                      child: ListTile(
                        leading: Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isCompleted
                              ? mainColorGreenBlue
                              : bgColorLight60,
                          size: 32,
                        ),
                        title: Text(
                          '完成状态',
                          style: dialogContentStyle.copyWith(
                            color: bgColorLight80,
                          ),
                        ),
                        subtitle: Text(
                          isCompleted ? '已完成' : '未完成',
                          style: dialogContentSmallStyle.copyWith(
                            color: bgColorLight60,
                          ),
                        ),
                        trailing: Switch(
                          value: isCompleted,
                          activeColor: mainColorGreenBlue,
                          onChanged: (value) {
                            setState(() {
                              isCompleted = value;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // 得分显示
                    Card(
                      color: mainColorPurple80,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '得分',
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
                      ...rule.bonusItems
                          .map(
                            (item) => _buildPointItemCard(
                              item: item,
                              isBonus: true,
                              isCompleted: isCompleted,
                            ),
                          )
                          .toList(),
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
                      ...rule.deductionItems
                          .map(
                            (item) => _buildPointItemCard(
                              item: item,
                              isBonus: false,
                              isCompleted: isCompleted,
                            ),
                          )
                          .toList(),
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
                            isCompleted: isCompleted,
                            score: score,
                          ),
                  );
                  await SchedulePointStorage.saveSchedulePointData(updatedData);
                  Navigator.of(context).pop();
                  completer.complete(isCompleted);
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

/// 构建评分项卡片
Widget _buildPointItemCard({
  required SchedulePointItem item,
  required bool isBonus,
  required bool isCompleted,
}) {
  return Card(
    color: mainColorPurple90,
    margin: EdgeInsets.only(bottom: 4),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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

  // 选择目标星期（排除当前星期）
  final List<int> targetOptions = List.generate(
    7,
    (i) => i,
  ).where((i) => i != sourceWeekIndex).toList();
  final Set<int> selectedTargets = {};

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
                  }).toList(),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: mainColorPurple90,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '提示：复制后会与目标星期的现有规则合并，不会覆盖原有规则。',
                      style: dialogContentSmallStyle.copyWith(
                        color: bgColorLight60,
                      ),
                    ),
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
