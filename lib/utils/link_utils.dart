import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/launch_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// 「学习通」关键字：事项内容里出现它时，可以直接点开学习通
const String chaoxingKeyword = '学习通';

/// 学习通（超星）Android 包名，用于按包名直接启动已安装的 App
const String chaoxingAndroidPackage = 'com.chaoxing.mobile';

/// 学习通 App 的 URL Scheme，按顺序尝试（不同版本可能不同）
const List<String> chaoxingUrlSchemes = ['chaoxing://', 'xxt://'];

/// 兜底入口：学习通网页版，任何平台都能打开
const String chaoxingWebUrl = 'https://i.chaoxing.com/';

/// 链接匹配：http(s):// 或 www. 开头，遇到空白、中英文标点即结束
final RegExp urlPattern = RegExp(
  r'''https?://[^\s，。；：！？、（）【】《》“”‘’"']+|www\.[^\s，。；：！？、（）【】《》“”‘’"']+''',
  caseSensitive: false,
);

/// 「学习通」关键字匹配：允许带【】/ [] / 「」 括号与空格，例如「【学习通】」
final RegExp chaoxingPattern = RegExp(r'[【\[「]?\s*学习通\s*[】\]」]?');

/// 事项内容里插入图片的标记：%img[<sha256>.<后缀>]%
///
/// 只存服务端的文件名（而不是完整网址），这样服务器地址变化后老内容依然可用
final RegExp toDoImagePattern = RegExp(
  r'%img\[([0-9a-f]{64}\.(?:jpg|jpeg|png|gif|webp|bmp))\]%',
);

/// 把事项里保存的图片名拼成可访问的地址
String toDoImageUrl(String name) => '${ApiService.url}/asset/image/$name';

/// 去掉内容里的图片标记，用于只展示纯文本的场景（例如提醒消息）
String stripToDoImageTags(String text, {String replacement = ''}) {
  if (text.isEmpty) return text;
  return text.replaceAll(toDoImagePattern, replacement);
}

/// 文本片段类型
enum RichTextSegmentType { text, link, chaoxing, image }

/// 切分后的文本片段
class RichTextSegment {
  final RichTextSegmentType type;

  /// 需要展示的文字（学习通片段一律展示为「学习通」，去掉括号）
  final String text;

  /// 链接片段对应的可打开地址
  final String? url;

  /// 图片片段对应的服务端文件名
  final String? imageName;

  const RichTextSegment(this.type, this.text, {this.url, this.imageName});
}

/// 去掉链接末尾常见的标点，避免把句号、右括号算进网址
String trimUrlTail(String url) {
  const tails = '.,;:!?)]}>"\'、';
  var result = url.trim();
  while (result.isNotEmpty && tails.contains(result[result.length - 1])) {
    result = result.substring(0, result.length - 1);
  }
  return result;
}

/// 把识别到的链接整理成可打开的地址：自动补全协议，只放行 http/https
Uri? toOpenableUri(String url) {
  final trimmed = trimUrlTail(url);
  if (trimmed.isEmpty) return null;
  final withScheme = trimmed.toLowerCase().startsWith('www.')
      ? 'https://$trimmed'
      : trimmed;
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  return uri;
}

/// 文本中是否提到学习通
bool containsChaoxingKeyword(String text) => chaoxingPattern.hasMatch(text);

/// 把一段文本切成「普通文本 / 链接 / 学习通 / 图片」片段，供富文本渲染使用
List<RichTextSegment> parseRichTextSegments(
  String text, {
  bool recognizeChaoxing = true,
}) {
  if (text.isEmpty) return const [];
  final matches =
      <({int start, int end, RichTextSegmentType type, String value})>[];
  for (final match in urlPattern.allMatches(text)) {
    matches.add((
      start: match.start,
      end: match.end,
      type: RichTextSegmentType.link,
      value: match.group(0)!,
    ));
  }
  if (recognizeChaoxing) {
    for (final match in chaoxingPattern.allMatches(text)) {
      matches.add((
        start: match.start,
        end: match.end,
        type: RichTextSegmentType.chaoxing,
        value: match.group(0)!,
      ));
    }
  }
  for (final match in toDoImagePattern.allMatches(text)) {
    // 图片片段只需要文件名，展示时再拼成地址
    matches.add((
      start: match.start,
      end: match.end,
      type: RichTextSegmentType.image,
      value: match.group(1)!,
    ));
  }
  matches.sort((a, b) => a.start.compareTo(b.start));

  final segments = <RichTextSegment>[];
  var cursor = 0;
  for (final match in matches) {
    // 与上一个片段重叠时跳过，避免文字重复
    if (match.start < cursor || match.end <= match.start) continue;
    if (match.start > cursor) {
      segments.add(
        RichTextSegment(
          RichTextSegmentType.text,
          text.substring(cursor, match.start),
        ),
      );
    }
    if (match.type == RichTextSegmentType.link) {
      final uri = toOpenableUri(match.value);
      if (uri == null) {
        segments.add(RichTextSegment(RichTextSegmentType.text, match.value));
      } else {
        segments.add(
          RichTextSegment(
            RichTextSegmentType.link,
            trimUrlTail(match.value),
            url: uri.toString(),
          ),
        );
      }
    } else if (match.type == RichTextSegmentType.image) {
      segments.add(
        RichTextSegment(
          RichTextSegmentType.image,
          toDoImageToken(match.value),
          imageName: match.value,
        ),
      );
    } else {
      segments.add(
        RichTextSegment(RichTextSegmentType.chaoxing, chaoxingKeyword),
      );
    }
    cursor = match.end;
  }
  if (cursor < text.length) {
    segments.add(
      RichTextSegment(RichTextSegmentType.text, text.substring(cursor)),
    );
  }
  return segments;
}

/// 由图片文件名还原出完整标记，便于把片段重新拼回原文
String toDoImageToken(String name) => '%img[$name]%';

/// 用系统浏览器 / 默认应用打开链接
Future<bool> openLinkUrl(String url) async {
  final uri = toOpenableUri(url);
  if (uri == null) return false;
  if (await _tryLaunchUrl(uri)) return true;
  await showToast(msg: "无法打开链接：$url");
  return false;
}

/// 打开学习通：先按包名唤起已安装的 App，再尝试 URL Scheme，
/// 都没成功时打开学习通网页版（保证点了有反馈）。
Future<bool> openChaoxing() async {
  final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  if (!kIsWeb && Platform.isAndroid) {
    // 按包名启动最可靠，不依赖 Scheme 是否猜对
    if (await LaunchService.openAppByPackage(chaoxingAndroidPackage)) {
      return true;
    }
  }
  if (isMobile) {
    for (final scheme in chaoxingUrlSchemes) {
      if (await _tryLaunchUrl(Uri.parse(scheme))) return true;
    }
  }
  if (await _tryLaunchUrl(Uri.parse(chaoxingWebUrl))) {
    if (isMobile) {
      await showToast(msg: "未检测到学习通 App，已打开网页版");
    }
    return true;
  }
  await showToast(msg: "无法打开学习通，请手动打开");
  return false;
}

/// 先问系统能不能处理，再直接尝试一次：部分机型上 canLaunchUrl 并不准
Future<bool> _tryLaunchUrl(
  Uri uri, {
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  try {
    if (await canLaunchUrl(uri) && await launchUrl(uri, mode: mode)) {
      return true;
    }
  } catch (e) {
    // 忽略：继续走下面的直接尝试
  }
  try {
    return await launchUrl(uri, mode: mode);
  } catch (e) {
    return false;
  }
}
