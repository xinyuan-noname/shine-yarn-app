// 作业事项模板：标题带「【作业】」前缀，内容写明科目与截止时间，
// 这样事项表既能一眼看出是作业，也能按科目筛选（见 to_do_subject_utils.dart）。

/// 作业模板的标题前缀
const String homeworkTitlePrefix = '【作业】';

/// 生成作业事项的标题与内容
({String title, String content}) buildHomeworkToDoTemplate({
  required String subject,
  required String homework,
  DateTime? deadline,
  bool withChaoxingTip = true,
}) {
  final normalizedSubject = subject.trim();
  final buffer = StringBuffer();
  if (normalizedSubject.isNotEmpty) {
    buffer.writeln('科目：$normalizedSubject');
  }
  final homeworkText = homework.trim();
  if (homeworkText.isNotEmpty) {
    buffer.writeln('作业内容：$homeworkText');
  }
  if (deadline != null) {
    buffer.writeln('截止时间：${formatToDoDeadline(deadline)}');
  }
  if (withChaoxingTip) {
    buffer.writeln('提交方式：学习通');
  }
  return (
    title: '$homeworkTitlePrefix$normalizedSubject',
    content: buffer.toString().trimRight(),
  );
}

/// 截止时间文案：同一年只显示「月-日 时:分」，跨年补上年份
String formatToDoDeadline(DateTime deadline, {DateTime? now}) {
  final current = now ?? DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  final monthDay = '${two(deadline.month)}-${two(deadline.day)}';
  final time = '${two(deadline.hour)}:${two(deadline.minute)}';
  if (deadline.year == current.year) return '$monthDay $time';
  return '${deadline.year}-$monthDay $time';
}
