
class CourseSchedule {
  final int weekday;
  final List<int> period;
  final List<int> weeks;
  final String location;
  int get start => period.elementAtOrNull(0) ?? 0;
  int get end => period.lastOrNull ?? 0;
  int get periodLength => end - start + 1;

  CourseSchedule({
    required this.weekday,
    required this.period,
    required this.weeks,
    required this.location,
  });

  factory CourseSchedule.fromJson(Map<String, dynamic> json) {
    return CourseSchedule(
      weekday: json['weekday'] ?? 0,
      period: List<int>.from(json['period'] ?? []),
      weeks: List<int>.from(json['weeks'] ?? []),
      location: json['location'] ?? '',
    );
  }
}

class CourseBasicInfo {
  final String subjectName;
  final String courseType;
  final List<String> teachers;
  final double? credit;
  final String? alias;
  final String? semester;

  CourseBasicInfo({
    required this.subjectName,
    required this.courseType,
    required this.teachers,
    this.credit,
    this.alias,
    this.semester,
  });

  factory CourseBasicInfo.fromJson(Map<String, dynamic> json) {
    return CourseBasicInfo(
      subjectName: json['subjectName'] ?? '',
      courseType: json['courseType'] ?? '',
      teachers: List<String>.from(json['teachers'] ?? []),
      credit: (json['credit'] is int)
          ? (json['credit'] as int).toDouble()
          : json['credit'],
      alias: json['alias'],
      semester: json['semester'],
    );
  }
}

class CourseData {
  final CourseBasicInfo basicInfo;
  final List<CourseSchedule> schedule;

  CourseData({required this.basicInfo, required this.schedule});

  factory CourseData.fromJson(Map<String, dynamic> json) {
    return CourseData(
      basicInfo: CourseBasicInfo.fromJson(json),
      schedule:
          (json['schedule'] as List?)
              ?.map((item) => CourseSchedule.fromJson(item))
              .toList() ??
          [],
    );
  }

  List<CourseSchedule>? findScheduleByWeek(int week) {
    final result = schedule.where((s) => s.weeks.contains(week)).toList();
    return result.isEmpty ? null : result;
  }

  String get subjectName => basicInfo.subjectName;
  String get courseType => basicInfo.courseType;
  List<String> get teachers => basicInfo.teachers;
  double? get credit => basicInfo.credit;
  String? get alias => basicInfo.alias;
  String? get semester => basicInfo.semester;
}

/// 单节课的安排数据
class ScheduleData {
  /// 学期名称
  final String semester;

  /// 周次
  final int week;

  /// 星期几 (1-7 对应周一到周日)
  final int weekday;

  /// 开始节次
  final int periodStart;

  /// 地点
  final String? location;

  /// 是否是实验课 (1 表示是实验，0 表示不是)
  final bool? isExperiment;

  /// 课程别名
  final String? alias;

  /// 作业信息
  final String? homework;

  /// 总结信息
  final String? summary;

  /// 问题信息
  final String? issue;

  const ScheduleData({
    required this.semester,
    required this.week,
    required this.weekday,
    required this.periodStart,
    this.location,
    this.isExperiment,
    this.alias,
    this.homework,
    this.summary,
    this.issue,
  });

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      semester: json['semester'],
      week: json['week'],
      weekday: json['weekday'],
      periodStart: json['period_start'],
      location: json['location'],
      isExperiment: json['isExperiment'],
      alias: json['alias'],
      homework: json['homework'],
      summary: json['summary'],
      issue: json['issue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semester': semester,
      'week': week,
      'weekday': weekday,
      'period_start': periodStart,
      'location': location,
      'isExperiment': isExperiment,
      'alias': alias,
      'homework': homework,
      'summary': summary,
      'issue': issue,
    };
  }

  ScheduleData copyWith({
    String? semester,
    int? week,
    int? weekday,
    int? periodStart,
    int? periodEnd,
    String? location,
    bool? isExperiment,
    String? alias,
    String? homework,
    String? summary,
    String? issue,
  }) {
    return ScheduleData(
      semester: semester ?? this.semester,
      week: week ?? this.week,
      weekday: weekday ?? this.weekday,
      periodStart: periodStart ?? this.periodStart,
      location: location ?? this.location,
      isExperiment: isExperiment ?? this.isExperiment,
      alias: alias ?? this.alias,
      homework: homework ?? this.homework,
      summary: summary ?? this.summary,
      issue: issue ?? this.issue,
    );
  }

  @override
  String toString() {
    return 'ScheduleData{semester: $semester, week: $week, weekday: $weekday, periodStart: $periodStart, location: $location, isExperiment: $isExperiment, alias: $alias, homework: $homework, summary: $summary, issue: $issue}';
  }
}
