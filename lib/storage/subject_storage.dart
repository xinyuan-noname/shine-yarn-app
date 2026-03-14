import 'package:shared_preferences/shared_preferences.dart';

class SubjectStorage {
  static final String _currentSubjectNameListKey = "current_subject_name_list_key";
    static Future<void> setCurrentSemesterName(List<String> subjectList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_currentSubjectNameListKey, subjectList);
  }

  static Future<List<String>?> getCurrentSemesterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_currentSubjectNameListKey);
  }

  static Future<void> delCurrentSemesterName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSubjectNameListKey);
  }
}