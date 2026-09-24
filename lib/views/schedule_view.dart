import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shine/components/bottom_sheet.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/extensions/list.dart';
import 'package:shine/models/schedule_reminder_data.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/services/notification.dart';
import 'package:shine/services/schedule_reminder_service.dart';
import 'package:shine/storage/elective_storage.dart';
import 'package:shine/storage/schedule_reminder_storage.dart';
import 'package:shine/storage/subject_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/models/course_data.dart';
import 'package:shine/utils/time_utils.dart';
import 'package:week_of_year/date_week_extensions.dart';

/// 基准尺寸，以 360 宽屏幕下的课表为基准，其它屏幕按比例自适应
const double _baseCellWidth = 35;
const double _baseCourseHeight = 60;

/// 单列最小宽度：240 宽屏幕下可用宽度仅 160，8 列即为 20，保证不会被压得更窄
const double _minCellWidth = 20;

/// 课表最小展示宽度，低于该宽度时提示用户
const double _minScreenWidth = 240;

/// 单节课的最小 / 最大高度（最大值会随文字缩放一起放大）
const double _minCourseHeight = _baseCourseHeight;
const double _maxCourseHeight = 120;

/// 文字缩放范围：窄屏适当缩小文字，避免挤在过窄的单元格里换行
const double _minTextScale = 0.8;
const double _maxTextScale = 1.8;

/// 列数：节次列 + 7 天
const int _columnCount = 8;
const double _cardPadding = 20;

const _baseTitleTextStyle = TextStyle(fontFamily: "SmileySans", fontSize: 12);
const _baseDayTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 10,
  color: Colors.grey,
);
const _basePeriodTextStyle = TextStyle(fontFamily: "SmileySans", fontSize: 10);
const _baseTimeTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 8,
  color: Colors.grey,
);
const _baseCourseTextStyle = TextStyle(fontFamily: "SmileySans", fontSize: 10);
const _baseLocationTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 10,
  color: bgColorLight,
);

/// 依据可用宽度求单列宽度，保证 8 列刚好铺满可用宽度
double _resolveCellWidth(double availableWidth) {
  return max(_minCellWidth, availableWidth / _columnCount);
}

/// 依据可用高度与节次数求单节课高度：空间足够时铺满可视区域，不足时保持最小高度并滚动
double _resolveCourseHeight(
  double availableHeight,
  int phaseCount,
  double textScale,
) {
  if (phaseCount <= 0) return _baseCourseHeight;
  return (availableHeight / phaseCount)
      .clamp(_minCourseHeight, _maxCourseHeight * textScale)
      .toDouble();
}

/// 课表自适应布局参数：列宽、课程行高、文字缩放均由可用空间推导
class _ScheduleLayout {
  /// 单列（节次列 / 某一天）宽度
  final double cellWidth;

  /// 单节课（一个节次）的高度
  final double courseHeight;

  const _ScheduleLayout({required this.cellWidth, required this.courseHeight});

  /// 只依据可用宽度推导，用于表头等与行高无关的部分
  factory _ScheduleLayout.fromWidth(double availableWidth) => _ScheduleLayout(
    cellWidth: _resolveCellWidth(availableWidth),
    courseHeight: _minCourseHeight,
  );

  _ScheduleLayout withCourseHeight(double height) =>
      _ScheduleLayout(cellWidth: cellWidth, courseHeight: height);

  /// 文字 / 图标相对基准尺寸的缩放比例
  double get textScale => (cellWidth / _baseCellWidth)
      .clamp(_minTextScale, _maxTextScale)
      .toDouble();

  TextStyle _scaled(TextStyle style) =>
      style.copyWith(fontSize: (style.fontSize ?? 0) * textScale);

  TextStyle get titleTextStyle => _scaled(_baseTitleTextStyle);
  TextStyle get dayTextStyle => _scaled(_baseDayTextStyle);
  TextStyle get periodTextStyle => _scaled(_basePeriodTextStyle);
  TextStyle get timeTextStyle => _scaled(_baseTimeTextStyle);
  TextStyle get courseTextStyle => _scaled(_baseCourseTextStyle);
  TextStyle get locationTextStyle => _scaled(_baseLocationTextStyle);

  /// 课程格内部的小间距 / 图标尺寸
  double get cellPadding => 2 * textScale;
  double get cellTopPadding => 5 * textScale;
  double get labIconSize => 10 * textScale;
}

const List<Color> _courseColorList = [
  mainColorPurple50,
  mainColorPurple60,
  mainColorPurple70,
  mainColorPurple80,
  mainColorPurple90,
  mainColorPurple95,
  deepColorPurple90,
  darkColorPurple,
];

typedef ChangeShowWeekCallback = void Function(DateTime d);

class ScheduleView extends StatefulWidget {
  final String? semesterName;
  final DateTime? semesterStartedAt;
  final List<List<TimeOfDay>> semesterPhaseList;
  final RefreshCallback onRefresh;
  final DateTime showDate;
  final List<CourseData> subjectInfoList;
  final List<ScheduleData> scheduleDataList;
  final ChangeShowWeekCallback onChangeShowDate;

  /// 提醒设置变化后的回调（用于重排系统通知）
  final VoidCallback? onReminderChanged;
  const ScheduleView({
    super.key,
    this.semesterName,
    this.semesterStartedAt,
    required this.semesterPhaseList,
    required this.scheduleDataList,
    required this.subjectInfoList,
    required this.onRefresh,
    required this.onChangeShowDate,
    required this.showDate,
    this.onReminderChanged,
  });

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  /// 专业任选课选课状态（科目名 -> 是否已选），仅保存在本地
  Map<String, bool> _electiveSelection = {};

  /// 日程提醒设置（科目名 -> 设置），仅保存在本地
  Map<String, ScheduleReminderSetting> _reminderSettings = {};

  @override
  void initState() {
    super.initState();
    _loadElectiveSelection();
    _loadReminderSettings();
  }

  @override
  void didUpdateWidget(covariant ScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 学期变化后读取该学期的选课状态
    if (oldWidget.semesterName != widget.semesterName) {
      _loadElectiveSelection();
    }
  }

  Future<void> _loadElectiveSelection() async {
    final selection = await ElectiveStorage.getSelection(widget.semesterName);
    if (!mounted) return;
    setState(() {
      _electiveSelection = selection;
    });
  }

  Future<void> _loadReminderSettings() async {
    final settings = await ScheduleReminderStorage.getSettings();
    if (!mounted) return;
    setState(() {
      _reminderSettings = settings;
    });
  }

  /// 该课程是否开启了上课提醒
  bool _isReminderEnabled(String subjectName) =>
      _reminderSettings[subjectName]?.enabled ?? false;

  /// 按指定提前量预览下次提醒的时间
  String? _reminderPreviewText(String subjectName, int leadMinutes) {
    final occurrences = buildScheduleReminderOccurrences(
      courseList: widget.subjectInfoList,
      settings: {
        subjectName: ScheduleReminderSetting(
          enabled: true,
          leadMinutes: leadMinutes,
        ),
      },
      phaseList: widget.semesterPhaseList,
      semesterStartedAt: widget.semesterStartedAt,
      horizonDays: ScheduleReminderService.horizonDays,
    );
    final first = occurrences.firstOrNull;
    if (first == null) return null;
    final weekNames = ['一', '二', '三', '四', '五', '六', '日'];
    final date = first.remindAt;
    return '下次提醒：${date.month}月${date.day}日（周${weekNames[first.weekday - 1]}）'
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        '，第 ${first.startPeriod}-${first.endPeriod} 节';
  }

  /// 打开统一的日程提醒管理
  Future<void> _openReminderManagerDialog() async {
    final courseList = _getReminderCourseList();
    if (courseList.isEmpty) {
      showToast(msg: "本学期暂无课程");
      return;
    }
    final result = await showScheduleReminderManagerDialog(
      context: context,
      courseList: courseList,
      settings: _reminderSettings,
      previewBuilder: _reminderPreviewText,
    );
    if (result == null) return;
    await ScheduleReminderStorage.saveSettings(result);
    if (result.values.any((setting) => setting.enabled)) {
      await NotificationService.requestPermission();
    }
    if (!mounted) return;
    setState(() {
      _reminderSettings = result;
    });
    widget.onReminderChanged?.call();
    final enabledCount = result.values
        .where((setting) => setting.enabled)
        .length;
    showToast(msg: enabledCount > 0 ? '已开启 $enabledCount 门课程的提醒' : '已关闭全部课程提醒');
  }

  /// 提醒管理里列出的课程（按科目名去重后排序）
  List<CourseData> _getReminderCourseList() {
    final Map<String, CourseData> result = {};
    for (final courseData in widget.subjectInfoList) {
      result.putIfAbsent(courseData.subjectName, () => courseData);
    }
    return result.values.toList()
      ..sort((a, b) => a.subjectName.compareTo(b.subjectName));
  }

  /// 打开某门课的提醒设置（课表详情弹窗里的快捷入口）
  Future<void> _openReminderDialog(CourseData courseData) async {
    final subjectName = courseData.subjectName;
    final setting =
        _reminderSettings[subjectName] ?? ScheduleReminderSetting.disabled;
    final result = await showScheduleReminderDialog(
      context: context,
      courseName: courseData.alias ?? subjectName,
      setting: setting,
      previewBuilder: (leadMinutes) =>
          _reminderPreviewText(subjectName, leadMinutes),
    );
    if (result == null) return;
    await ScheduleReminderStorage.setSetting(subjectName, result);
    if (result.enabled) {
      await NotificationService.requestPermission();
    }
    if (!mounted) return;
    setState(() {
      _reminderSettings = {..._reminderSettings, subjectName: result};
    });
    widget.onReminderChanged?.call();
    showToast(msg: result.enabled ? '已开启提醒（${result.leadText}）' : '已关闭该课程的提醒');
  }

  /// 专业任选课默认视为已选，只有本地显式记录为未选时才隐藏
  bool _isElectiveSelected(String subjectName) =>
      _electiveSelection[subjectName] ?? true;

  /// 实验课对应的母课程（按科目名去掉「实验」后缀匹配），找不到返回 null
  CourseData? _getBaseCourse(CourseData subject) {
    if (!subject.isExperiment) return null;
    final baseName = subject.experimentBaseName;
    if (baseName.isEmpty || baseName == subject.subjectName) return null;
    for (final courseData in widget.subjectInfoList) {
      if (courseData.subjectName == baseName) return courseData;
    }
    return null;
  }

  /// 决定该课程显示状态的专业任选课科目名：
  /// 实验课跟随母课程（母课程是专业任选课时按母课程判断），不受选课状态影响时返回 null
  String? _getElectiveOwnerName(CourseData subject) {
    final baseCourse = _getBaseCourse(subject);
    if (baseCourse != null && baseCourse.isMajorElective) {
      return baseCourse.subjectName;
    }
    return subject.isMajorElective ? subject.subjectName : null;
  }

  /// 课程是否需要在课表中显示：未选的专业任选课及其实验课都不显示
  bool _isSubjectVisible(CourseData subject) {
    final owner = _getElectiveOwnerName(subject);
    if (owner == null) return true;
    return _isElectiveSelected(owner);
  }

  /// 本学期可作为独立选课项的专业任选课（实验课跟随母课程，不单独列出）
  List<CourseData> _getElectiveCourseList() {
    final Map<String, CourseData> result = {};
    for (final courseData in widget.subjectInfoList) {
      if (_getElectiveOwnerName(courseData) != courseData.subjectName) continue;
      result.putIfAbsent(courseData.subjectName, () => courseData);
    }
    return result.values.toList()
      ..sort((a, b) => a.subjectName.compareTo(b.subjectName));
  }

  /// 打开专业任选课选课设置
  Future<void> _openElectiveSettingDialog() async {
    final electiveList = _getElectiveCourseList();
    if (electiveList.isEmpty) {
      showToast(msg: "本学期暂无专业任选课");
      return;
    }
    final result = await showElectiveSelectionDialog(
      context: context,
      electiveList: electiveList,
      selection: _electiveSelection,
      semesterName: widget.semesterName,
    );
    if (result == null) return;
    await ElectiveStorage.saveSelection(widget.semesterName, result);
    if (!mounted) return;
    setState(() {
      _electiveSelection = result;
    });
    final selectedCount = result.values.where((value) => value).length;
    showToast(msg: "已选 $selectedCount/${result.length} 门专业任选课");
  }

  @override
  Widget build(BuildContext context) {
    try {
      final Size screenSize = MediaQuery.of(context).size;
      if (screenSize.width < _minScreenWidth) {
        return Container(
          alignment: Alignment.topCenter,
          child: const Text(
            "宽度不足以展示课表！",
            style: viewEmptyTextStyle,
            textAlign: TextAlign.center,
          ),
        );
      }
      return SizedBox.expand(
        child: Container(
          padding: bodyPadding,
          child: Container(
            padding: const EdgeInsets.all(_cardPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
              gradient: whiteLinearGradient,
            ),
            // 按可用宽度推导列宽，使表格恰好铺满屏幕宽度
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columnLayout = _ScheduleLayout.fromWidth(
                  constraints.maxWidth,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.semesterName ?? "未知学期"}(第${_getCurrentWeek()}周)",
                      style: labelStyle,
                    ),
                    bottomLine,
                    SizedBox(
                      // 用 Wrap 兜底：窄屏上选修课入口会自动换行，不会溢出
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          InkWell(
                            onTap: () async {
                              if (widget.semesterStartedAt == null) return;
                              final result = await showWeekBottomSheet(
                                context,
                                startedAt: widget.semesterStartedAt!,
                                selectedDate: widget.showDate,
                              );
                              if (result != null) {
                                widget.onChangeShowDate(result);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.only(
                                top: 1,
                                bottom: 1,
                                left: 20,
                                right: 18,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: mainColorGreenBlue,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10,
                                    color: mainColorGrey20,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                '第${_getShowTimeWeek()}周▼',
                                style: const TextStyle(
                                  fontFamily: "SmileySans",
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _genElectiveEntry(),
                              const SizedBox(width: 6),
                              _genReminderEntry(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 表格区域占满剩余高度，随屏幕高度自适应
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: bgColorLight,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: columnLayout.cellWidth,
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${widget.showDate.month}月',
                                      style: columnLayout.titleTextStyle,
                                    ),
                                  ),
                                ),
                                ..._genTableTitleList(context, columnLayout),
                              ],
                            ),
                            bottomLineSmall,
                            // 依据剩余高度计算单节课高度，空间足够时无需滚动
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, bodyConstraints) {
                                  final layout = columnLayout.withCourseHeight(
                                    _resolveCourseHeight(
                                      bodyConstraints.maxHeight,
                                      widget.semesterPhaseList.length,
                                      columnLayout.textScale,
                                    ),
                                  );
                                  return RefreshIndicator(
                                    onRefresh: widget.onRefresh,
                                    child: SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          _genPhaseList(layout),
                                          ..._genCourseColumn(context, layout),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      SubjectStorage.delCurrentDiySubjectInfo().then((_) {
        HomePageRefreshNotifier.refreshSchedule();
      });
      return const Text("数据出错", style: viewEmptyTextStyle);
    }
  }

  /// 专业任选课入口：显示已选 / 总数，点击进入选课设置（本地保存）
  Widget _genElectiveEntry() {
    final electiveList = _getElectiveCourseList();
    if (electiveList.isEmpty) return const SizedBox.shrink();
    final selectedCount = electiveList
        .where((courseData) => _isElectiveSelected(courseData.subjectName))
        .length;
    return InkWell(
      onTap: _openElectiveSettingDialog,
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: '专业任选课设置（橙色为已选课程）',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: orangeLinearGradient,
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: mainColorOrange50,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.playlist_add_check,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                '选修课 $selectedCount/${electiveList.length}',
                style: const TextStyle(
                  fontFamily: "SmileySans",
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 日程提醒统一入口：一个按钮管理所有课程的提醒
  Widget _genReminderEntry() {
    final enabledCount = _reminderSettings.values
        .where((setting) => setting.enabled)
        .length;
    return InkWell(
      onTap: _openReminderManagerDialog,
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: '日程提醒设置（课格左下角橙色铃铛表示已开启）',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: purpleLinearGradient,
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: mainColorPurple40,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enabledCount > 0
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                enabledCount > 0 ? '提醒 $enabledCount' : '提醒',
                style: const TextStyle(
                  fontFamily: "SmileySans",
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _genTableTitleList(
    BuildContext context,
    _ScheduleLayout layout,
  ) {
    return getWeekDates(widget.showDate)
        .map(
          (d) => GestureDetector(
            onLongPress: () {
              showSchedulePointDialog(context: context);
            },
            onDoubleTap: () {
              showDailySchedulePointDialog(
                context: context,
                date: d,
                weekday: d.weekday,
              );
            },
            child: Container(
              width: layout.cellWidth,
              color: isToday(d) ? mainColorGreenBlue : Colors.transparent,
              child: Column(
                children: [
                  Text(getCnWeekDayName(d), style: layout.titleTextStyle),
                  Text(d.day.toString(), style: layout.dayTextStyle),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  List<(CourseBasicInfo, CourseSchedule)> _getshowSubjectInfoList() {
    final List<(CourseBasicInfo, CourseSchedule)> result = [];
    for (final subject in widget.subjectInfoList) {
      // 未选的专业任选课不出现在自己的课表中
      if (!_isSubjectVisible(subject)) continue;
      final schedule = subject.findScheduleByWeek(_getShowTimeWeek());
      if (schedule == null) continue;
      for (final scheduleItem in schedule) {
        result.add((subject.basicInfo, scheduleItem));
      }
    }
    result.sort((a, b) {
      final r = a.$2.weekday.compareTo(b.$2.weekday);
      if (r == 0) return a.$2.period[0].compareTo(b.$2.period[0]);
      return r;
    });
    return result;
  }

  List<ScheduleData> _getShowScheduleDataList() {
    final result = widget.scheduleDataList.where((element) {
      return element.week == _getShowTimeWeek();
    }).toList();
    result.sort((a, b) {
      final r = a.weekday.compareTo(b.weekday);
      if (r == 0) return a.periodStart.compareTo(b.periodStart);
      return r;
    });
    return result;
  }

  List<Widget> _genCourseColumn(BuildContext context, _ScheduleLayout layout) {
    final courseList = _getshowSubjectInfoList();
    final scheduleDataList = _getShowScheduleDataList();
    return getWeekDates(widget.showDate).map((d) {
      return Container(
        decoration: isToday(d)
            ? BoxDecoration(boxShadow: [BoxShadow(color: mainColorGreenBlue)])
            : null,
        width: layout.cellWidth,
        child: Column(
          // 让课程格铺满整列宽度
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _genCourseRow(
            context: context,
            courseList: courseList,
            date: d,
            scheduleDataList: scheduleDataList,
            layout: layout,
          ),
        ),
      );
    }).toList();
  }

  Widget _genEmptyCourse(
    BuildContext context, {
    required int weekday,
    required int startPeriod,
    required _ScheduleLayout layout,
  }) {
    return GestureDetector(
      child: Container(
        height: layout.courseHeight,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: mainColorGrey20)),
        ),
      ),
      onTap: () async {
        final data = await showCourseDataEditDialog(
          context: context,
          courseData: CourseData(
            basicInfo: CourseBasicInfo(
              subjectName: '',
              courseType: '选修课',
              credit: 0.0,
              semester: widget.semesterName,
            ),
            schedule: [
              CourseSchedule(
                weekday: weekday,
                period: [startPeriod, startPeriod + 1],
                weeks: [_getWeek(widget.showDate)],
                location: '',
              ),
            ],
          ),
        );
        if (data != null) {
          await SubjectStorage.addCurrentDiySubjectInfo(data);
          HomePageRefreshNotifier.refreshSchedule();
        }
      },
    );
  }

  bool _isLabClass(
    (CourseBasicInfo, CourseSchedule) scheduleItem,
    ScheduleData? scheduleData,
  ) {
    // 课程类型为「实验」或科目名带「实验」后缀（如「数字信号处理实验」）都算实验课
    return scheduleItem.$1.isExperiment || scheduleData?.isExperiment == true;
  }

  String _getLocation(
    (CourseBasicInfo, CourseSchedule) scheduleItem,
    ScheduleData? scheduleData,
  ) {
    final dataLocation = scheduleData?.location;
    if (dataLocation is String && dataLocation.isNotEmpty) {
      return dataLocation;
    }
    if (scheduleItem.$2.location.isNotEmpty) {
      return scheduleItem.$2.location;
    }
    return "暂无场地信息";
  }

  String _getCourseName(
    (CourseBasicInfo, CourseSchedule) scheduleItem,
    ScheduleData? scheduleData,
  ) {
    final aliasData = scheduleData?.alias;
    if (aliasData is String && aliasData.isNotEmpty) return aliasData;
    return scheduleItem.$1.alias ?? scheduleItem.$1.subjectName;
  }

  /// 专业任选课及其实验课统一橙色，其它课程按星期取色
  Color _getCourseColor(int weekdayIndex, CourseData courseData) {
    if (_getElectiveOwnerName(courseData) != null) return deepColorOrange;
    return _courseColorList.elementAt(weekdayIndex);
  }

  List<Widget> _genCourseRow({
    required List<(CourseBasicInfo, CourseSchedule)> courseList,
    required DateTime date,
    required List<ScheduleData> scheduleDataList,
    required BuildContext context,
    required _ScheduleLayout layout,
  }) {
    final List<Widget> children = [];
    final index = date.weekday - 1;
    for (int i = 1; i <= widget.semesterPhaseList.length; i++) {
      ScheduleData? currentScheduleData = scheduleDataList.elementAtOrNull(0);
      final scheduleItem = courseList.elementAtOrNull(0);
      for (final item in courseList) {
        if (item == scheduleItem) continue;
        if (item.$2.weekday == date.weekday && item.$2.start == i) {
          courseList.remove(item);
        } else {
          break;
        }
      }
      if (scheduleItem == null) {
        children.add(
          _genEmptyCourse(
            context,
            weekday: date.weekday,
            startPeriod: i,
            layout: layout,
          ),
        );
        continue;
      }
      if (scheduleItem.$2.weekday == date.weekday &&
          scheduleItem.$2.start == i) {
        ScheduleData? mappedScheduleData;
        if (currentScheduleData?.weekday == date.weekday &&
            currentScheduleData?.periodStart == i) {
          mappedScheduleData = scheduleDataList.safeRemoveAt(0);
        }
        String courseName = _getCourseName(scheduleItem, mappedScheduleData);
        String location = _getLocation(scheduleItem, mappedScheduleData);
        CourseData courseData = widget.subjectInfoList.firstWhere(
          (data) => data.subjectName == scheduleItem.$1.subjectName,
        );
        children.add(
          InkWell(
            onTap: () {
              showScheduleDialog(
                context: context,
                courseName: courseName,
                location: location,
                courseInfo: scheduleItem.$1,
                courseSchedule: scheduleItem.$2,
                scheduleData: mappedScheduleData,
                onJump: (name) {
                  HomePageRefreshNotifier.viewGoto(3);
                  HomePageRefreshNotifier.flagViewGoto(1);
                  HomePageRefreshNotifier.changeResource(name);
                },
                isDiy: SubjectStorage.diySubjectNameList.contains(
                  scheduleItem.$1.subjectName,
                ),
                courseData: courseData,
                onReminder: () => _openReminderDialog(courseData),
                reminderEnabled: _isReminderEnabled(
                  scheduleItem.$1.subjectName,
                ),
              );
            },
            onLongPress: () async {
              if (SubjectStorage.diySubjectNameList.contains(
                scheduleItem.$1.subjectName,
              )) {
                final data = await showCourseDataEditDialog(
                  context: context,
                  courseData: courseData,
                );
                if (data != null) {
                  await SubjectStorage.removeCurrentDiySubjectInfo(
                    scheduleItem.$1.subjectName,
                  );
                  await SubjectStorage.addCurrentDiySubjectInfo(data);
                  HomePageRefreshNotifier.refreshSchedule();
                }
              }
            },
            child: Container(
              height: layout.courseHeight * scheduleItem.$2.periodLength,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: bgColorLight),
                  left: BorderSide(color: bgColorLight),
                ),
                color: _getCourseColor(index, courseData),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Stack(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: layout.cellPadding) +
                        EdgeInsets.only(top: layout.cellTopPadding),
                    child: Wrap(
                      children: [
                        Text(courseName, style: layout.courseTextStyle),
                        Text(location, style: layout.locationTextStyle),
                      ],
                    ),
                  ),
                  if (_isLabClass(scheduleItem, mappedScheduleData))
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(layout.cellPadding),
                        decoration: BoxDecoration(
                          color: mainColorRed,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.science,
                          size: layout.labIconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // 已开启上课提醒的课程打个铃铛标
                  if (_isReminderEnabled(scheduleItem.$1.subjectName))
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.all(layout.cellPadding),
                        decoration: BoxDecoration(
                          color: deepColorOrange,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active,
                          size: layout.labIconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        i = scheduleItem.$2.end;
        courseList.remove(scheduleItem);
        continue;
      }
      children.add(
        _genEmptyCourse(
          context,
          weekday: date.weekday,
          startPeriod: i,
          layout: layout,
        ),
      );
    }
    return children;
  }

  Widget _genPhaseList(_ScheduleLayout layout) {
    return SizedBox(
      width: layout.cellWidth,
      child: Column(
        children: List.generate(widget.semesterPhaseList.length, (index) {
          final phase = widget.semesterPhaseList[index];
          final start = phase[0];
          final end = phase[1];
          return SizedBox(
            height: layout.courseHeight,
            child: Column(
              children: [
                Text((index + 1).toString(), style: layout.periodTextStyle),
                Text(
                  '${start.hour >= 10 ? start.hour : '0${start.hour}'}:${start.minute >= 10 ? start.minute : '0${start.minute}'}',
                  style: layout.timeTextStyle,
                ),
                Text(
                  '${end.hour >= 10 ? end.hour : '0${end.hour}'}:${end.minute >= 10 ? end.minute : '0${end.minute}'}',
                  style: layout.timeTextStyle,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  int _getCurrentWeek() {
    return _getWeek(DateTime.now());
  }

  int _getWeek(DateTime d) {
    if (widget.semesterStartedAt == null) return 0;
    final s = widget.semesterStartedAt?.weekOfYear ?? 1;
    final e = d.weekOfYear;
    return e - s + 1;
  }

  int _getShowTimeWeek() {
    return _getWeek(widget.showDate);
  }
}
