import 'dart:convert';

import 'package:shine/storage/message_storage.dart';
import 'package:shine/utils/string_utils.dart';

/// 匿名消息的协议约定：
/// - 来源 id 固定为 [anonymousMessageSourceId]（fffffffff），不携带真实身份
/// - 来源昵称使用随机名字
///
/// 服务器没有匿名功能，因此发送端直接把来源写进提醒消息，
/// 由服务端原样转发给目标用户。

/// 判断接收到的提醒消息是否为匿名消息
bool isAnonymousMessage(Map message, Map sourceMap) {
  return message["anonymous"] == true ||
      sourceMap["anonymous"] == true ||
      sourceMap["id"] == anonymousMessageSourceId;
}

/// 取出匿名消息的随机昵称，没有可用昵称时在本地生成一个
String resolveAnonymousNickname(Map message, Map sourceMap) {
  var nickname = sourceMap['username'] is String
      ? sourceMap['username'] as String
      : "";
  // 发送端自带的随机昵称优先级最高：即使服务端用自己的 source 覆盖了来源，
  // 接收端也不会显示发送者的真实昵称
  if (message['anonymousName'] is String &&
      (message['anonymousName'] as String).isNotEmpty) {
    nickname = message['anonymousName'] as String;
  }
  if (nickname.isEmpty) nickname = randomNickname();
  return nickname;
}

/// 生成匿名消息的来源信息，返回 (source JSON, 展示用昵称)
(String, String) buildAnonymousSource(Map message, Map sourceMap) {
  final nickname = resolveAnonymousNickname(message, sourceMap);
  final source = jsonEncode({
    "id": anonymousMessageSourceId,
    "username": nickname,
    "anonymous": true,
  });
  return (source, nickname);
}

/// 构造匿名消息发送时附加到提醒消息中的字段
///
/// source 与服务器下发的 source 一样是 JSON 字符串，
/// anonymous 与 anonymousName 用于服务端覆盖 source 时兜底判定
Map<String, dynamic> buildAnonymousPayloadFields() {
  final nickname = randomNickname();
  return {
    "source": jsonEncode({
      "id": anonymousMessageSourceId,
      "username": nickname,
      "anonymous": true,
    }),
    "anonymous": true,
    "anonymousName": nickname,
  };
}
