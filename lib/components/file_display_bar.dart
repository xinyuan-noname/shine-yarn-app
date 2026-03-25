import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/file_utils.dart';

class FileDisplayBar extends StatelessWidget {
  final String fileName;
  final int? fileSize;
  final Uint8List? fileData;
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
    this.fileData,
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
              child: _buildFileIcon(
                fileName,
                size: hugeIconSize,
                fileData: fileData,
              ),
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

  Widget _buildFileIcon(String fileName, {double? size, Uint8List? fileData}) {
    if (fileName.endsWith(".pdf")) {
      return Image.asset('assets/icons/pdf.png', width: size, height: size);
    } else if (fileName.endsWith(".doc")) {
      return Image.asset('assets/icons/doc.png', width: size, height: size);
    } else if (fileName.endsWith(".dotx")) {
      return Image.asset('assets/icons/dotx.png', width: size, height: size);
    } else if (fileName.endsWith(".xlsx")) {
      return Image.asset('assets/icons/xlsx.png', width: size, height: size);
    } else if (fileName.endsWith(".xls")) {
      return Image.asset('assets/icons/xls.png', width: size, height: size);
    } else if (fileName.endsWith(".pptx") || fileName.endsWith(".ppt")) {
      return Image.asset('assets/icons/ppt.png', width: size, height: size);
    } else if (fileName.endsWith(".zip")) {
      return Image.asset('assets/icons/zip.png', width: size, height: size);
    } else if (fileName.endsWith(".rar")) {
      return Image.asset('assets/icons/rar.png', width: size, height: size);
    } else if (isImageFile(fileName)) {
      if (fileData != null) {
        return Image.memory(fileData, width: size, height: size);
      }
      return Icon(Icons.image, size: size, color: Colors.purple);
    } else {
      return Icon(Icons.description, size: size, color: Colors.grey);
    }
  }
}
