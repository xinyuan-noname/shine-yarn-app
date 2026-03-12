import 'package:shine/extensions/list.dart';

class CourseSchedule {
  final int weekday;
  final List<int> period;
  final List<int> weeks;
  final String location;
  int get start => period.safeElementAt(0) ?? 0;
  int get end => period.safeLast ?? 0;
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
