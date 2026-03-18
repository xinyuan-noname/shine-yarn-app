import 'package:flutter/material.dart';

/// MIME 类型下拉选择组件
///
/// 用于选择文件上传格式的限制类型
class MimeTypeDropdown extends StatelessWidget {
  /// 当前选中的 MIME 类型
  final String value;

  /// 值改变时的回调
  final Function(String) onChanged;

  /// 是否显示"不限格式"选项
  final bool showUnlimited;

  /// 自定义的 MIME 类型选项（可选）
  final List<MapEntry<String, String>>? customOptions;

  const MimeTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.showUnlimited = true,
    this.customOptions,
  });
  
  static const List<MapEntry<String, String>> defaultOptions = [
    MapEntry(
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "word 文档",
    ),
    MapEntry("application/pdf", "pdf 文档"),
    MapEntry(
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "excel 表格",
    ),
    MapEntry("image", "图片"),
    MapEntry("image/jpeg", "jpg 图片"),
    MapEntry("image/png", "png 图片"),
    MapEntry("video/mp4", "mp4 视频"),
    MapEntry("application/zip", "zip 压缩包"),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      style: const TextStyle(
        fontFamily: "SmileySans",
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      value: value.isEmpty ? null : value,
      hint: const Text("请选择文件格式"),
      items: [
        if (showUnlimited)
          const DropdownMenuItem(value: "", child: Text("不限格式")),
        ..._buildOptions(customOptions ?? defaultOptions),
      ],
      onChanged: (String? newValue) {
        if (newValue == null) return;
        onChanged(newValue);
      },
      isExpanded: true,
    );
  }

  List<DropdownMenuItem<String>> _buildOptions(
    List<MapEntry<String, String>> options,
  ) {
    return options.map((entry) {
      return DropdownMenuItem(value: entry.key, child: Text(entry.value));
    }).toList();
  }
}
