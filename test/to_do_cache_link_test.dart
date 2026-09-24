import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/components/link_text.dart';
import 'package:shine/models/to_do_item_data.dart';
import 'package:shine/storage/to_do_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/link_utils.dart';

ToDoItemData _item({
  required String itemId,
  String title = '标题',
  String content = '内容',
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

  group('事项表本地缓存', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('默认没有缓存', () async {
      expect(await ToDoStorage.getToDoList(), isEmpty);
    });

    test('保存后可完整读回', () async {
      await ToDoStorage.saveToDoList([
        _item(itemId: 'a', title: '交作业', content: '今晚 12 点前'),
        _item(itemId: 'b', source: '学委'),
      ]);
      final cached = await ToDoStorage.getToDoList();
      expect(cached.length, 2);
      expect(cached.first.itemId, 'a');
      expect(cached.first.title, '交作业');
      expect(cached.first.content, '今晚 12 点前');
      expect(cached[1].source, '学委');
    });

    test('删除事项后缓存同步移除', () async {
      await ToDoStorage.saveToDoList([_item(itemId: 'a'), _item(itemId: 'b')]);
      await ToDoStorage.removeToDoItem('a');
      final cached = await ToDoStorage.getToDoList();
      expect(cached.map((e) => e.itemId), ['b']);
      // 删除不存在的 id 不会破坏缓存
      await ToDoStorage.removeToDoItem('不存在');
      expect((await ToDoStorage.getToDoList()).length, 1);
    });

    test('修改事项后缓存同步更新且保留来源与时间', () async {
      await ToDoStorage.saveToDoList([
        _item(itemId: 'a', title: '旧标题', content: '旧内容', source: '班长'),
      ]);
      await ToDoStorage.updateToDoItem(
        itemId: 'a',
        title: '新标题',
        content: '新内容',
      );
      final cached = await ToDoStorage.getToDoList();
      expect(cached.single.title, '新标题');
      expect(cached.single.content, '新内容');
      expect(cached.single.source, '班长');
      expect(cached.single.ts, 1700000000000);
    });

    test('缓存内容损坏时按空列表处理', () async {
      SharedPreferences.setMockInitialValues({
        'public_to_do_list_cache_key': 'not a json',
      });
      expect(await ToDoStorage.getToDoList(), isEmpty);
    });

    test('缓存里混入非法条目时跳过该条目', () async {
      SharedPreferences.setMockInitialValues({
        'public_to_do_list_cache_key': '[{"itemId":"a","title":"ok"}, 42]',
      });
      final cached = await ToDoStorage.getToDoList();
      expect(cached.length, 1);
      expect(cached.single.itemId, 'a');
      expect(cached.single.content, '');
      expect(cached.single.ts, 0);
    });
  });

  group('链接与学习通关键字识别', () {
    test('识别 http/https/www 链接', () {
      final segments = parseRichTextSegments(
        '详见 https://example.com/a?b=1 和 www.test.cn/x',
      );
      final links = segments
          .where((s) => s.type == RichTextSegmentType.link)
          .toList();
      expect(links.length, 2);
      expect(links[0].text, 'https://example.com/a?b=1');
      expect(links[0].url, 'https://example.com/a?b=1');
      // www 开头的地址自动补全协议
      expect(links[1].url, 'https://www.test.cn/x');
    });

    test('链接末尾的中英文标点不会被算进网址', () {
      final segments = parseRichTextSegments('打开 https://example.com/a。谢谢');
      final link = segments.firstWhere(
        (s) => s.type == RichTextSegmentType.link,
      );
      expect(link.url, 'https://example.com/a');
      final segments2 = parseRichTextSegments('(见 https://example.com/b)');
      final link2 = segments2.firstWhere(
        (s) => s.type == RichTextSegmentType.link,
      );
      expect(link2.url, 'https://example.com/b');
    });

    test('识别【学习通】等写法', () {
      for (final text in ['【学习通】完成作业', '学习通上有新任务', '[学习通]签到']) {
        expect(containsChaoxingKeyword(text), isTrue, reason: text);
        final segment = parseRichTextSegments(
          text,
        ).firstWhere((s) => s.type == RichTextSegmentType.chaoxing);
        // 标签统一显示为「学习通」，去掉括号
        expect(segment.text, '学习通');
      }
      expect(containsChaoxingKeyword('普通通知'), isFalse);
    });

    test('普通文本不会被误判成链接', () {
      final segments = parseRichTextSegments('明天 8:30 在 A101 交作业，成绩按 3.5 计');
      expect(segments.every((s) => s.type == RichTextSegmentType.text), isTrue);
      expect(
        segments.map((s) => s.text).join(),
        '明天 8:30 在 A101 交作业，成绩按 3.5 计',
      );
    });

    test('只放行 http/https 协议', () {
      expect(toOpenableUri('https://a.com'), isNotNull);
      expect(toOpenableUri('www.a.com'), isNotNull);
      expect(toOpenableUri('javascript:alert(1)'), isNull);
      expect(toOpenableUri('chaoxing://x'), isNull);
    });
  });

  group('事项图片标记', () {
    final String imageName = '${'a' * 64}.png';

    test('识别 %img[名称]% 标记', () {
      final segments = parseRichTextSegments(
        '明天交作业 %img[$imageName]% 记得打印',
      );
      final images = segments
          .where((s) => s.type == RichTextSegmentType.image)
          .toList();
      expect(images.length, 1);
      expect(images.single.imageName, imageName);
      // 拼回原文时标记保持完整
      expect(segments.map((s) => s.text).join(), '明天交作业 %img[$imageName]% 记得打印');
    });

    test('多个图片标记都能识别', () {
      final other = '${'b' * 64}.jpg';
      final segments = parseRichTextSegments(
        '%img[$imageName]%\n%img[$other]%',
      );
      final images = segments
          .where((s) => s.type == RichTextSegmentType.image)
          .toList();
      expect(images.map((s) => s.imageName), [imageName, other]);
    });

    test('非法标记按普通文字处理', () {
      for (final text in [
        '%img[../secret.png]%',
        '%img[abc.png]%',
        '%img[${'a' * 64}.exe]%',
      ]) {
        final segments = parseRichTextSegments(text);
        expect(
          segments.every((s) => s.type == RichTextSegmentType.text),
          isTrue,
          reason: text,
        );
        expect(segments.map((s) => s.text).join(), text);
      }
    });

    test('绝对地址写法不会被当成图片标记', () {
      // 图片标记只认服务端文件名，写出完整网址时退化成普通链接
      final text = '%img[https://a.com/x.png]%';
      final segments = parseRichTextSegments(text);
      expect(
        segments.any((s) => s.type == RichTextSegmentType.image),
        isFalse,
      );
      expect(segments.any((s) => s.type == RichTextSegmentType.link), isTrue);
      expect(segments.map((s) => s.text).join(), text);
    });

    test('图片标记与链接可以混排', () {
      final segments = parseRichTextSegments(
        '见 https://example.com/a 和 %img[$imageName]%',
      );
      expect(
        segments.map((s) => s.type),
        [
          RichTextSegmentType.text,
          RichTextSegmentType.link,
          RichTextSegmentType.text,
          RichTextSegmentType.image,
        ],
      );
    });

    test('清理标记后可用于纯文本消息', () {
      final content = '交作业 %img[$imageName]% 别忘了';
      expect(stripToDoImageTags(content), '交作业  别忘了');
      expect(stripToDoImageTags('没有图片'), '没有图片');
      expect(
        stripToDoImageTags(content, replacement: '[图片]'),
        '交作业 [图片] 别忘了',
      );
    });

    test('图片地址按当前服务器地址拼接', () {
      expect(toDoImageUrl(imageName), endsWith('/asset/image/$imageName'));
    });
  });

  group('LinkText 渲染与点击', () {
    Future<void> pumpLinkText(
      WidgetTester tester, {
      required String text,
      required List<String> openedLinks,
      required List<int> chaoxingTaps,
      VoidCallback? onContentTap,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: onContentTap,
              child: LinkText(
                text,
                style: const TextStyle(fontSize: 16),
                onOpenLink: (url) async {
                  openedLinks.add(url);
                  return true;
                },
                onOpenChaoxing: () async {
                  chaoxingTaps.add(1);
                  return true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('链接标蓝并可点击打开', (WidgetTester tester) async {
      final opened = <String>[];
      await pumpLinkText(
        tester,
        text: '通知见 https://example.com/notice',
        openedLinks: opened,
        chaoxingTaps: [],
      );
      final text = tester.widget<Text>(find.byType(Text));
      final span = text.textSpan! as TextSpan;
      final linkSpan = span.children!.whereType<TextSpan>().firstWhere(
        (s) => s.text == 'https://example.com/notice',
      );
      expect(linkSpan.style?.color, mainColorLinkBlue);
      expect(linkSpan.style?.decoration, TextDecoration.underline);
      expect(linkSpan.recognizer, isNotNull);

      await tester.tapOnText(
        find.textRange.ofSubstring('https://example.com/notice'),
      );
      await tester.pump();
      expect(opened, ['https://example.com/notice']);
    });

    testWidgets('点击链接不会触发外层的事项编辑', (WidgetTester tester) async {
      var contentTaps = 0;
      final opened = <String>[];
      await pumpLinkText(
        tester,
        text: '通知见 https://example.com/notice',
        openedLinks: opened,
        chaoxingTaps: [],
        onContentTap: () => contentTaps++,
      );
      await tester.tapOnText(
        find.textRange.ofSubstring('https://example.com/notice'),
      );
      await tester.pump();
      expect(opened.length, 1);
      expect(contentTaps, 0);

      // 点普通文字依然走外层
      await tester.tapOnText(find.textRange.ofSubstring('通知见'));
      await tester.pump();
      expect(contentTaps, 1);
    });

    testWidgets('【学习通】渲染成可点击标签且不会触发事项编辑', (WidgetTester tester) async {
      var contentTaps = 0;
      final chaoxingTaps = <int>[];
      await pumpLinkText(
        tester,
        text: '【学习通】请完成本周作业',
        openedLinks: [],
        chaoxingTaps: chaoxingTaps,
        onContentTap: () => contentTaps++,
      );
      expect(find.text('学习通'), findsOneWidget);
      await tester.tap(find.text('学习通'));
      await tester.pump();
      expect(chaoxingTaps.length, 1);
      expect(contentTaps, 0);
    });

    testWidgets('关闭关键字识别后不再显示学习通标签', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LinkText(
              '【学习通】请完成本周作业',
              recognizeChaoxing: false,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('学习通'), findsNothing);
    });

    testWidgets('图片标记渲染成图片且点击可看大图', (WidgetTester tester) async {
      final imageName = '${'c' * 64}.png';
      final opened = <(String, String)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinkText(
              '作业如图 %img[$imageName]% 请查收',
              style: const TextStyle(fontSize: 16),
              onOpenImage: (name, url) async {
                opened.add((name, url));
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      // 标记本身不再作为文字出现
      expect(find.textContaining('%img['), findsNothing);

      await tester.tap(find.byType(CachedNetworkImage));
      await tester.pump();
      expect(opened.length, 1);
      expect(opened.single.$1, imageName);
      expect(opened.single.$2, endsWith('/asset/image/$imageName'));
    });

    testWidgets('showImages 关闭时图片标记按文字展示', (WidgetTester tester) async {
      final imageName = '${'d' * 64}.png';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinkText(
              '标题 %img[$imageName]%',
              showImages: false,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.textContaining('%img['), findsOneWidget);
    });
  });
}
