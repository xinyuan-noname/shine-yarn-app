import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/link_utils.dart';

/// 展示一段文本，并自动识别其中的内容：
///
/// - 链接（http/https、www 开头）标蓝加下划线，点击用系统浏览器打开；
/// - 「学习通」关键字渲染成小标签，点击直接打开学习通。
///
/// [onOpenLink] / [onOpenChaoxing] 只在测试或需要自定义跳转时传入，
/// 默认走 [openLinkUrl] 与 [openChaoxing]。
class LinkText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  /// 链接文字样式，默认基于 [style] 派生为蓝色下划线
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// 是否识别「学习通」关键字
  final bool recognizeChaoxing;

  final Future<bool> Function(String url)? onOpenLink;
  final Future<bool> Function()? onOpenChaoxing;

  const LinkText(
    this.text, {
    super.key,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.recognizeChaoxing = true,
    this.onOpenLink,
    this.onOpenChaoxing,
  });

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  /// 每次重建都会生成新的手势识别器，先释放上一批
  void _clearRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _openLink(String url) async {
    if (widget.onOpenLink != null) {
      await widget.onOpenLink!(url);
      return;
    }
    await openLinkUrl(url);
  }

  Future<void> _openChaoxing() async {
    if (widget.onOpenChaoxing != null) {
      await widget.onOpenChaoxing!();
      return;
    }
    await openChaoxing();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final linkStyle =
        widget.linkStyle ??
        baseStyle.copyWith(
          color: mainColorLinkBlue,
          decoration: TextDecoration.underline,
          decorationColor: mainColorLinkBlue,
        );
    final segments = parseRichTextSegments(
      widget.text,
      recognizeChaoxing: widget.recognizeChaoxing,
    );
    _clearRecognizers();
    final spans = <InlineSpan>[];
    for (final segment in segments) {
      switch (segment.type) {
        case RichTextSegmentType.link:
          final url = segment.url;
          if (url == null) {
            spans.add(TextSpan(text: segment.text, style: baseStyle));
            break;
          }
          final recognizer = TapGestureRecognizer()
            ..onTap = () {
              _openLink(url);
            };
          _recognizers.add(recognizer);
          spans.add(
            TextSpan(
              text: segment.text,
              style: linkStyle,
              recognizer: recognizer,
            ),
          );
        case RichTextSegmentType.chaoxing:
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _buildChaoxingTag(),
            ),
          );
        case RichTextSegmentType.text:
          spans.add(TextSpan(text: segment.text, style: baseStyle));
      }
    }
    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }

  /// 「学习通」关键字标签，点击打开学习通
  Widget _buildChaoxingTag() {
    return GestureDetector(
      onTap: () {
        _openChaoxing();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: mainColorGreenBlue30,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: mainColorLinkBlue, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school, size: 12, color: mainColorLinkBlue),
            const SizedBox(width: 2),
            Text(
              chaoxingKeyword,
              style: const TextStyle(
                fontFamily: "SmileySans",
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: mainColorLinkBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
