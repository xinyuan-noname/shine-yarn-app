import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shine/models/to_do_item_data.dart';
import 'package:shine/utils/to_do_subject_utils.dart';
import 'package:shine/utils/to_do_template_utils.dart';
import 'package:shine/views/flag_view.dart';

ToDoItemData _item({
  required String itemId,
  String title = '',
  String content = '',
  String source = '班长',
  int ts = 1700000000000,
}) {
  return ToDoItemData(
    itemId: itemId,
    title: title,
    content: content,
    source: source,
    ts: ts,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const subjectList = ['高等数学', '数字信号处理', '数字信号处理实验', '大学物理实验'];

  group('科目表规范化', () {
    test('实验课归到母课程并去重', () {
      expect(normalizeSubjectList(subjectList), ['高等数学', '数字信号处理', '大学物理']);
    });

    test('空名字与重复项被丢弃', () {
      expect(normalizeSubjectList(['', '  ', '英语', '英语']), ['英语']);
    });
  });

  group('事项科目识别', () {
    test('标题或内容里出现科目名即算命中', () {
      expect(
        resolveToDoSubject(
          _item(itemId: 'a', title: '高等数学作业'),
          normalizeSubjectList(subjectList),
        ),
        '高等数学',
      );
      expect(
        resolveToDoSubject(
          _item(itemId: 'b', content: '明天交数字信号处理第三章习题'),
          normalizeSubjectList(subjectList),
        ),
        '数字信号处理',
      );
    });

    test('同时命中多个科目时取更长的名字', () {
      final subjects = normalizeSubjectList(subjectList);
      expect(
        resolveToDoSubject(_item(itemId: 'a', content: '数字信号处理实验报告'), subjects),
        '数字信号处理',
      );
      // 未在科目表里的实验课也能被归到母课程
      expect(
        resolveToDoSubject(_item(itemId: 'b', title: '大学物理实验预习'), subjects),
        '大学物理',
      );
    });

    test('没匹配到科目表时读取「科目：xxx」标注', () {
      expect(
        resolveToDoSubject(
          _item(itemId: 'a', content: '科目：形势与政策\n作业内容：写心得'),
          subjectList,
        ),
        '形势与政策',
      );
    });

    test('没有科目信息时返回 null', () {
      expect(
        resolveToDoSubject(_item(itemId: 'a', title: '开会'), subjectList),
        isNull,
      );
    });
  });

  group('按科目筛选', () {
    final subjects = normalizeSubjectList(subjectList);
    final items = [
      _item(itemId: 'a', title: '高等数学作业'),
      _item(itemId: 'b', title: '数字信号处理实验报告'),
      _item(itemId: 'c', title: '班会通知'),
    ];

    test('筛选出该科目的事项', () {
      final result = filterToDoListBySubject(items, '数字信号处理', subjects);
      expect(result.map((e) => e.itemId), ['b']);
    });

    test('筛选「全部」返回原列表', () {
      expect(filterToDoListBySubject(items, null, subjects).length, 3);
    });

    test('统计数量与科目汇总', () {
      expect(countToDoInSubject(items, null, subjects), 3);
      expect(countToDoInSubject(items, '高等数学', subjects), 1);
      expect(collectToDoSubjects(items, subjects), ['高等数学', '数字信号处理']);
    });

    test('科目表外的科目按出现顺序补在后面', () {
      final list = [...items, _item(itemId: 'd', content: '科目：形势与政策')];
      expect(collectToDoSubjects(list, subjects), ['高等数学', '数字信号处理', '形势与政策']);
    });
  });

  group('作业事项模板', () {
    test('标题带前缀，内容包含科目与截止时间', () {
      final result = buildHomeworkToDoTemplate(
        subject: '数字信号处理',
        homework: '第三章习题 1-10',
        deadline: DateTime(2026, 3, 10, 23, 59),
      );
      expect(result.title, '【作业】数字信号处理');
      expect(result.content, contains('科目：数字信号处理'));
      expect(result.content, contains('作业内容：第三章习题 1-10'));
      expect(result.content, contains('截止时间：03-10 23:59'));
      expect(result.content, contains('提交方式：学习通'));
      // 模板生成的内容能被按科目筛选命中
      expect(
        resolveToDoSubject(
          _item(itemId: 'a', title: result.title, content: result.content),
          ['数字信号处理'],
        ),
        '数字信号处理',
      );
    });

    test('可以不带学习通提示、不带截止时间', () {
      final result = buildHomeworkToDoTemplate(
        subject: '英语',
        homework: '',
        withChaoxingTip: false,
      );
      expect(result.title, '【作业】英语');
      expect(result.content, '科目：英语');
    });

    test('只填作业内容时标题不出现空科目', () {
      final result = buildHomeworkToDoTemplate(
        subject: '',
        homework: '背单词',
        withChaoxingTip: false,
      );
      expect(result.title, '【作业】');
      expect(result.content, '作业内容：背单词');
    });

    test('跨年的截止时间补上年份', () {
      expect(
        formatToDoDeadline(
          DateTime(2027, 1, 5, 8, 0),
          now: DateTime(2026, 12, 20),
        ),
        '2027-01-05 08:00',
      );
      expect(
        formatToDoDeadline(
          DateTime(2026, 1, 5, 8, 0),
          now: DateTime(2026, 12, 20),
        ),
        '01-05 08:00',
      );
    });
  });

  group('科目简写', () {
    test('超过三个字截断成「前三个字…」', () {
      expect(abbreviateSubjectName('数字信号处理'), '数字信…');
      expect(abbreviateSubjectName('大学物理'), '大学物…');
      expect(abbreviateSubjectName('马克思主义基本原理'), '马克思…');
    });

    test('不超过三个字原样显示', () {
      expect(abbreviateSubjectName('高数'), '高数');
      expect(abbreviateSubjectName('英语'), '英语');
      expect(abbreviateSubjectName('数字信号'), '数字信号');
      expect(abbreviateSubjectName('  高数  '), '高数');
    });

    test('可以指定保留字数', () {
      expect(abbreviateSubjectName('数字信号处理', maxChars: 2), '数字…');
      expect(abbreviateSubjectName('数字信号处理', maxChars: 6), '数字信号处理');
    });
  });

  group('事项表科目筛选界面', () {
    Widget buildFlagView({
      required List<ToDoItemData> items,
      required String? filter,
      required Function(String?) onChangeFilter,
      required TabController tabController,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FlagView(
            unfinishedItemList: items,
            finishedItemList: const [],
            onRefresh: () async {},
            updateFinishedStatus: () {},
            tabController: tabController,
            subjectsList: const [],
            currentSubject: '',
            onChangeSubject: (_) {},
            resourceList: const [],
            toDoSubjectList: const ['高等数学', '数字信号处理'],
            toDoSubjectFilter: filter,
            onChangeToDoSubjectFilter: onChangeFilter,
          ),
        ),
      );
    }

    testWidgets('点科目标签只显示该科目的事项', (WidgetTester tester) async {
      final items = [
        _item(itemId: 'a', title: '高等数学作业'),
        _item(itemId: 'b', title: '数字信号处理作业'),
      ];
      final tabController = TabController(length: 3, vsync: const TestVSync());
      addTearDown(tabController.dispose);
      String? filter;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildFlagView(
              items: items,
              filter: filter,
              tabController: tabController,
              onChangeFilter: (subject) {
                setState(() {
                  filter = subject;
                });
              },
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // 未筛选时两门课的事项都在
      expect(find.text('高等数学作业', findRichText: true), findsOneWidget);
      expect(find.text('数字信号处理作业', findRichText: true), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);

      // 点「数字信号处理」标签后只剩该科目的事项
      await tester.tap(find.text('数字信号处理').first);
      await tester.pumpAndSettle();
      expect(find.text('数字信号处理作业', findRichText: true), findsOneWidget);
      expect(find.text('高等数学作业', findRichText: true), findsNothing);

      // 点「全部」恢复
      await tester.tap(find.text('全部'));
      await tester.pumpAndSettle();
      expect(find.text('高等数学作业', findRichText: true), findsOneWidget);
    });

    testWidgets('卡片上的科目用简写，全名只留在筛选胶囊里', (WidgetTester tester) async {
      final tabController = TabController(length: 3, vsync: const TestVSync());
      addTearDown(tabController.dispose);

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildFlagView(
              items: [_item(itemId: 'b', title: '数字信号处理作业')],
              filter: null,
              tabController: tabController,
              onChangeFilter: (_) {},
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // 卡片上是简写（截断成前三个字 + 省略号）
      expect(find.text('数字信…'), findsOneWidget);
      // 全名只出现在筛选胶囊里
      expect(find.text('数字信号处理'), findsOneWidget);
    });

    testWidgets('筛选后没有事项时给出提示并能切回全部', (WidgetTester tester) async {
      final tabController = TabController(length: 3, vsync: const TestVSync());
      addTearDown(tabController.dispose);
      String? filter = '数字信号处理';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildFlagView(
              items: [_item(itemId: 'a', title: '高等数学作业')],
              filter: filter,
              tabController: tabController,
              onChangeFilter: (subject) {
                setState(() {
                  filter = subject;
                });
              },
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('「数字信号处理」暂无事项'), findsOneWidget);
      await tester.tap(find.text('查看全部事项'));
      await tester.pumpAndSettle();
      expect(find.text('高等数学作业', findRichText: true), findsOneWidget);
    });
  });
}
