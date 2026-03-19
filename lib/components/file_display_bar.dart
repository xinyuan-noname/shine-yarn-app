import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/file_utils.dart';

class FileDisplayBar extends StatelessWidget {
  final String fileName;
  final int? fileSize;
  final int maxLines;
  final VoidCallback? onPress;
  // final TextStyle? fileNameStyle;
  // final TextStyle? fileSizeStyle;

  const FileDisplayBar({
    super.key,
    required this.fileName,
    this.fileSize,
    this.maxLines = 1,
    this.onPress,
    // this.fileNameStyle,
    // this.fileSizeStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        padding: EdgeInsets.all(5),
        margin: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: whiteLinearGradient,
          border: Border.all(color: mainColorGrey40),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: mainColorGrey20),
              ),
              child: FileIcon(fileName, size: hugeIconSize),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '文件名：$fileName',
                    style: const TextStyle(
                      fontFamily: 'SmileySans',
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: maxLines,
                  ),
                  if (fileSize is int)
                    Text(
                      '文件大小：${formatBytes(fileSize)}',
                      style: const TextStyle(
                        fontFamily: 'SmileySans',
                        fontSize: 12,
                      ),
                      maxLines: maxLines,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
