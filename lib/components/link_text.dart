import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shine/pages/view_image_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/link_utils.dart';

/// 展示一段文本，并自动识别其中的内容：
///
/// - 链接（http/https、www 开头）标蓝加下划线，点击用系统浏览器打开；
/// - 「学习通」关键字渲染成小标签，点击直接打开学习通；
/// - 事项里插入的图片标记（%img[文件名]%）直接渲染成缩略图，点击看大图。
///
/// [onOpenLink] / [onOpenChaoxing] / [onOpenImage] 只在测试或需要自定义跳转时传入，
/// 默认走 [openLinkUrl]、[openChaoxing] 与图片查看页。
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

  /// 是否把图片标记渲染成图片，标题这类单行文本里可以关掉只留文字
  final bool showImages;

  final Future<bool> Function(String url)? onOpenLink;
  final Future<bool> Function()? onOpenChaoxing;
  final Future<bool> Function(String name, String url)? onOpenImage;

  const LinkText(
    this.text, {
    super.key,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.recognizeChaoxing = true,
    this.showImages = true,
    this.onOpenLink,
    this.onOpenChaoxing,
    this.onOpenImage,
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

  Future<void> _openImage(String name, String url) async {
    if (widget.onOpenImage != null) {
      await widget.onOpenImage!(name, url);
      return;
    }
    await globalNavigatorKey.currentState?.pushNamed(
      '/view/image',
      arguments: ViewImagePageArgs(
        url: url,
        filename: name,
        downloadable: true,
      ),
    );
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
        case RichTextSegmentType.image:
          final imageName = segment.imageName;
          if (!widget.showImages || imageName == null) {
            spans.add(TextSpan(text: segment.text, style: baseStyle));
            break;
          }
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _buildImage(imageName),
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

  /// 事项里插入的图片缩略图，点击看大图
  Widget _buildImage(String name) {
    final url = toDoImageUrl(name);
    return GestureDetector(
      onTap: () {
        _openImage(name, url);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColorLight60,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: mainColorGrey40, width: 0.8),
        ),
        child: CachedNetworkImage(
          imageUrl: url,
          httpHeaders: ApiService.headers.cast<String, String>(),
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            width: 120,
            height: 90,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => const SizedBox(
            width: 120,
            height: 90,
            child: Center(
              child: Icon(Icons.broken_image, color: mainColorGrey),
            ),
          ),
        ),
      ),
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
