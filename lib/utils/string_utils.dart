import 'dart:convert';
import 'dart:math';

String nowBase64() => base64Encode(
  DateTime.now().millisecondsSinceEpoch.toRadixString(10).codeUnits,
);

const List<String> _nicknamePrefixList = [
  "安静的",
  "温柔的",
  "神秘的",
  "快乐的",
  "迷路的",
  "认真的",
  "爱笑的",
  "发呆的",
  "好奇的",
  "慢热的",
  "沉默的",
  "早起的",
  "深夜的",
  "打盹的",
  "散步的",
  "看海的",
];

const List<String> _nicknameSuffixList = [
  "松鼠",
  "海豚",
  "猫头鹰",
  "萤火虫",
  "小鹿",
  "鲸鱼",
  "云朵",
  "星星",
  "旅人",
  "橘猫",
  "企鹅",
  "仙人掌",
  "蒲公英",
  "月亮",
  "雨伞",
  "柠檬",
  "路灯",
  "面包",
];

final Random _nicknameRandom = Random();

/// 生成一个随机昵称，用于匿名消息的展示，不包含任何真实身份信息
String randomNickname() {
  final prefix = _nicknamePrefixList[_nicknameRandom.nextInt(
    _nicknamePrefixList.length,
  )];
  final suffix = _nicknameSuffixList[_nicknameRandom.nextInt(
    _nicknameSuffixList.length,
  )];
  return "$prefix$suffix";
}
