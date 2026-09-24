/// 专业任选课在课程类型中的关键字，课程类型含该关键字即视为专业任选课
const String majorElectiveKeyword = '专业任选';

/// 判断课程类型是否为专业任选课（兼容「专业任选课」「专业任选」「专业任选(限选)」等写法）
bool isMajorElectiveCourseType(String? courseType) =>
    (courseType ?? '').contains(majorElectiveKeyword);

/// 实验课后缀：科目名以此结尾说明它是某门课程的实验课（如「数字信号处理实验」）
const List<String> experimentSuffixList = ['（实验）', '(实验)', '实验'];

/// 是否为实验课：课程类型为「实验」，或科目名带「实验」后缀
bool isExperimentCourseType(String? courseType, String? subjectName) {
  if ((courseType ?? '').trim() == '实验') return true;
  final name = (subjectName ?? '').trim();
  return name.isNotEmpty && resolveExperimentBaseName(name) != name;
}

/// 去掉实验后缀得到母课程名，非实验课返回科目名本身
String resolveExperimentBaseName(String subjectName) {
  final name = subjectName.trim();
  for (final suffix in experimentSuffixList) {
    if (name.endsWith(suffix) && name.length > suffix.length) {
      return name.substring(0, name.length - suffix.length).trim();
    }
  }
  return name;
}

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

  Map<String, dynamic> toJson() {
    return {
      'weekday': weekday,
      'period': period,
      'weeks': weeks,
      'location': location,
    };
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
    this.teachers = const [],
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

  Map<String, dynamic> toJson() {
    return {
      'subjectName': subjectName,
      'courseType': courseType,
      'teachers': teachers,
      'credit': credit,
      'alias': alias,
      'semester': semester,
    };
  }

  /// 是否为专业任选课
  bool get isMajorElective => isMajorElectiveCourseType(courseType);

  /// 是否为实验课（课程类型为「实验」，或科目名带「实验」后缀）
  bool get isExperiment => isExperimentCourseType(courseType, subjectName);

  /// 去掉实验后缀后的母课程名，非实验课返回科目名本身
  String get experimentBaseName => resolveExperimentBaseName(subjectName);
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

  Map<String, dynamic> toJson() {
    return {
      ...basicInfo.toJson(),
      'schedule': schedule.map((s) => s.toJson()).toList(),
    };
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

  /// 是否为专业任选课
  bool get isMajorElective => basicInfo.isMajorElective;

  /// 是否为实验课（课程类型为「实验」，或科目名带「实验」后缀）
  bool get isExperiment => basicInfo.isExperiment;

  /// 去掉实验后缀后的母课程名，非实验课返回科目名本身
  String get experimentBaseName => basicInfo.experimentBaseName;
}

class ScheduleData {
  final String semester;

  final int week;

  final int weekday;

  final int periodStart;

  final String? location;

  final bool? isExperiment;

  final String? alias;

  final String? homework;

  final String? summary;

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
