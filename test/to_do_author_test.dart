import 'package:flutter_test/flutter_test.dart';
import 'package:shine/utils/to_do_author_utils.dart';

void main() {
  group('事项作者判断', () {
    test('来源是昵称时算自己的', () {
      expect(
        isMyToDoItem(itemSource: '小明', username: '小明', position: null),
        isTrue,
      );
    });

    test('历史数据存职务时也认得出', () {
      expect(
        isMyToDoItem(itemSource: '班长', username: '小明', position: '班长'),
        isTrue,
      );
    });

    test('服务端回传用户 ID 时也认得出', () {
      expect(
        isMyToDoItem(itemSource: 'u1001', username: '小明', userId: 'u1001'),
        isTrue,
      );
    });

    test('别人的事项不算自己的', () {
      expect(
        isMyToDoItem(
          itemSource: '小红',
          username: '小明',
          position: '班长',
          userId: 'u1001',
        ),
        isFalse,
      );
    });

    test('忽略首尾空白与大小写', () {
      expect(
        isMyToDoItem(itemSource: '  XiaoMing ', username: 'xiaoming'),
        isTrue,
      );
    });

    test('来源为空时无法确认作者，不算自己的', () {
      expect(
        isMyToDoItem(itemSource: '', username: '小明', position: '班长'),
        isFalse,
      );
      expect(isMyToDoItem(itemSource: '   ', username: '小明'), isFalse);
    });

    test('自己的标识为空时不会误判', () {
      expect(
        isMyToDoItem(itemSource: '小明', username: '', position: null, userId: ''),
        isFalse,
      );
    });
  });

  group('事项操作权限', () {
    test('作者本人可以操作', () {
      expect(
        canOperateToDoItem(itemSource: '小明', username: '小明'),
        isTrue,
      );
    });

    test('管理员可以管理别人的事项', () {
      expect(
        canOperateToDoItem(
          itemSource: '小红',
          username: '小明',
          isAdmin: true,
        ),
        isTrue,
      );
    });

    test('普通同学不能操作别人的事项', () {
      expect(
        canOperateToDoItem(itemSource: '小红', username: '小明'),
        isFalse,
      );
    });
  });

  group('事项来源展示与署名', () {
    test('有来源时原样展示', () {
      expect(toDoSourceLabel(' 小明 '), '小明');
    });

    test('来源为空时给兜底文案，避免卡片空一行', () {
      expect(toDoSourceLabel(''), unknownToDoAuthorLabel);
      expect(toDoSourceLabel('   '), unknownToDoAuthorLabel);
    });

    test('发布署名优先昵称，没昵称时退回职务', () {
      expect(toDoPublisherSource(username: '小明', position: '班长'), '小明');
      expect(toDoPublisherSource(username: '', position: '班长'), '班长');
      expect(toDoPublisherSource(username: null, position: null), '');
    });
  });
}
