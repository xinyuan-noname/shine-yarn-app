import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/utils/anonymous_utils.dart';
import 'package:shine/utils/string_utils.dart';

void main() {
  group('isAnonymousMessage', () {
    test('按 anonymous 标记识别匿名消息', () {
      expect(isAnonymousMessage({"anonymous": true}, {}), true);
      expect(isAnonymousMessage({}, {"anonymous": true}), true);
      expect(
        isAnonymousMessage({}, {"id": "2023001", "username": "小李"}),
        false,
      );
    });

    test('来源id为 fffffffff 时视为匿名消息', () {
      expect(anonymousMessageSourceId, "fffffffff");
      expect(isAnonymousMessage({}, {"id": anonymousMessageSourceId}), true);
    });
  });

  group('buildAnonymousSource', () {
    test('优先使用发送端携带的随机昵称，且不保留真实身份', () {
      final (source, username) = buildAnonymousSource(
        {"anonymous": true, "anonymousName": "安静的海豚"},
        {"id": "2023001", "username": "小李"},
      );

      expect(username, "安静的海豚");
      final decoded = jsonDecode(source) as Map;
      expect(decoded["id"], anonymousMessageSourceId);
      expect(decoded["username"], "安静的海豚");
      expect(decoded["anonymous"], true);
      expect(source.contains("2023001"), isFalse);
      expect(source.contains("小李"), isFalse);
    });

    test('没有发送端昵称时使用服务端给出的昵称', () {
      final (source, username) = buildAnonymousSource(
        {"anonymous": true},
        {"id": anonymousMessageSourceId, "username": "迷路的小鹿"},
      );

      expect(username, "迷路的小鹿");
      expect((jsonDecode(source) as Map)["username"], "迷路的小鹿");
    });

    test('昵称缺失时本地生成随机昵称', () {
      final (source, username) = buildAnonymousSource(
        {"anonymous": true},
        {"id": anonymousMessageSourceId},
      );

      expect(username, isNotEmpty);
      expect((jsonDecode(source) as Map)["username"], username);
    });
  });

  group('buildAnonymousPayloadFields', () {
    test('发送时直接指定来源为 fffffffff + 随机昵称', () {
      final fields = buildAnonymousPayloadFields();

      expect(fields["anonymous"], true);
      // source 与服务器下发的 source 一样是 JSON 字符串
      final source = fields["source"];
      expect(source, isA<String>());
      final decoded = jsonDecode(source as String) as Map;
      expect(decoded["id"], anonymousMessageSourceId);
      expect(decoded["anonymous"], true);
      final nickname = decoded["username"] as String;
      expect(nickname, isNotEmpty);
      expect(fields["anonymousName"], nickname);
    });

    test('每次发送使用不同的随机昵称(具有随机性)', () {
      final nicknames = {
        for (var i = 0; i < 60; i++)
          (jsonDecode(buildAnonymousPayloadFields()["source"] as String)
                  as Map)["username"]
              as String,
      };
      expect(nicknames.length, greaterThan(1));
    });
  });

  group('randomNickname', () {
    test('生成非空且具有随机性的昵称', () {
      final names = {for (var i = 0; i < 80; i++) randomNickname()};
      expect(names.length, greaterThan(1));
      for (final name in names) {
        expect(name, isNotEmpty);
        expect(name.length, greaterThan(2));
      }
    });
  });
}
