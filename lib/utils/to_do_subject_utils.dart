import 'package:shine/models/course_data.dart';
import 'package:shine/models/to_do_item_data.dart';

/// 事项表「全部」筛选项的文案
const String allSubjectLabel = '全部';

/// 显式科目标注：科目：数字信号处理 / 科目: 数字信号处理
final RegExp subjectLabelPattern = RegExp(r'科目\s*[:：]\s*([^\s，,。;；、\n]+)');

/// 规范化科目名：去掉「实验」后缀与首尾空白，让实验课与理论课归到同一科目
String normalizeSubjectName(String name) =>
    resolveExperimentBaseName(name.trim()).trim();

/// 科目表去重并保持原有顺序
List<String> normalizeSubjectList(Iterable<String> names) {
  final result = <String>[];
  final seen = <String>{};
  for (final name in names) {
    final normalized = normalizeSubjectName(name);
    if (normalized.isEmpty || !seen.add(normalized)) continue;
    result.add(normalized);
  }
  return result;
}

/// 从事项里解析所属科目。
///
/// 先按已知科目名匹配（更长的名字优先，避免「数学」抢走「高等数学」），
/// 没匹配上时再读取文本里显式写出的「科目：xxx」。
String? resolveToDoSubject(ToDoItemData item, List<String> subjectList) {
  final text = '${item.title}\n${item.content}';
  String? matched;
  for (final subject in subjectList) {
    if (subject.isEmpty || !text.contains(subject)) continue;
    if (matched == null || subject.length > matched.length) {
      matched = subject;
    }
  }
  if (matched != null) return matched;
  final captured = subjectLabelPattern.firstMatch(text)?.group(1)?.trim();
  if (captured == null || captured.isEmpty) return null;
  return captured;
}

/// 事项是否属于指定科目，[subject] 为 null 表示「全部」
bool isToDoInSubject(
  ToDoItemData item,
  String? subject,
  List<String> subjectList,
) {
  if (subject == null) return true;
  return resolveToDoSubject(item, subjectList) == subject;
}

/// 按科目筛选事项，[subject] 为 null 时返回全部
List<ToDoItemData> filterToDoListBySubject(
  List<ToDoItemData> items,
  String? subject,
  List<String> subjectList,
) {
  if (subject == null) return List<ToDoItemData>.of(items);
  return items
      .where((item) => isToDoInSubject(item, subject, subjectList))
      .toList();
}

/// 统计某科目下的事项数量
int countToDoInSubject(
  Iterable<ToDoItemData> items,
  String? subject,
  List<String> subjectList,
) {
  if (subject == null) return items.length;
  return items.where((item) => isToDoInSubject(item, subject, subjectList)).length;
}

/// 汇总事项表中真实出现过的科目：科目表里命中的排前面，其余按出现顺序补充
List<String> collectToDoSubjects(
  Iterable<ToDoItemData> items,
  List<String> subjectList,
) {
  final found = <String>{};
  for (final item in items) {
    final subject = resolveToDoSubject(item, subjectList);
    if (subject != null) found.add(subject);
  }
  final ordered = <String>[];
  for (final subject in subjectList) {
    if (found.contains(subject)) ordered.add(subject);
  }
  for (final subject in found) {
    if (!ordered.contains(subject)) ordered.add(subject);
  }
  return ordered;
}
