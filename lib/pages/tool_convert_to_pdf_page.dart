import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/file_display_bar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/services/api_asset.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/debouncer_utils.dart';
import 'package:shine/utils/file_utils.dart';
import 'package:shine/utils/message_utils.dart';
import 'package:shine/utils/security_utils.dart';

class ToolConvertToPdfPage extends StatefulWidget {
  const ToolConvertToPdfPage({super.key});

  @override
  State<ToolConvertToPdfPage> createState() => _ToolConvertToPdfPageState();
}

class _ToolConvertToPdfPageState extends State<ToolConvertToPdfPage> {
  PlatformFile? _selectedFile;
  String _downloadUrl = '';
  bool _canConvert = false;
  final _controller = TextEditingController(text: "*.pdf");
  final _fileNameDebouncer = Debouncer();
  final ValueNotifier<String> _message = ValueNotifier("");
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Container(
            height: 900,
            padding: bodyPadding,
            child: SizedBox.expand(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                  gradient: whiteLinearGradient,
                ),
                child: _buildBodyContent(),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text("转为pdf", style: titleTextStyle),
      centerTitle: true,
      bottom: bottomLine,
    );
  }

  Widget _buildBodyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "要转化的文件：",
          style: TextStyle(fontFamily: 'SmileySans', fontSize: 16),
        ),
        bottomLine,
        _buildRawFilePart(),
        const SizedBox(height: 5),
        const Text(
          "转化后的文件：",
          style: TextStyle(fontFamily: 'SmileySans', fontSize: 16),
        ),
        bottomLine,
        _buildConvertedFilePart(),
      ],
    );
  }

  Widget _buildRawFilePart() {
    final List<Widget> children = [];
    if (_selectedFile != null) {
      children.add(
        FileDisplayBar(
          fileName: _selectedFile!.name,
          fileSize: _selectedFile!.bytes?.length,
          maxLines: 2,
          onPress: () async {
            showToast(msg: "暂不支持预览该文件");
          },
        ),
      );
    }
    children.add(
      InkWell(
        onTap: () async {
          final exts = documentExtensions.toList()..remove('pdf');
          PlatformFile? file = await pickFile(exts: exts);
          if (file == null || file.bytes == null) return;
          _selectedFile = file;
          final p = file.name.lastIndexOf('.');
          if (p != -1) {
            _controller.text = '${file.name.substring(0, p)}.pdf';
          }
          _canConvert = true;
          _downloadUrl = '';
          setState(() {});
        },
        child: Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            border: Border.all(color: mainColorGrey20),
            gradient: whiteLinearGradient,
          ),
          child: Icon(
            _selectedFile == null ? Icons.add : Icons.sync,
            size: largeIconSize,
            color: Colors.grey,
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildConvertedFilePart() {
    final List<Widget> children = [];
    children.add(
      const Text(
        "文件名：",
        style: TextStyle(fontFamily: 'SmileySans', fontSize: 16),
      ),
    );
    children.add(
      Transform.translate(
        offset: Offset(-5, 0),
        child: TextField(
          maxLines: 2,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(0),
            focusedBorder: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(),
          ),
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 16,
            color: Colors.grey,
          ),
          controller: _controller,
          enabled: _selectedFile != null,
          onChanged: (value) {
            _fileNameDebouncer.run(() {
              if (!value.endsWith('.pdf')) {
                _controller.text = value.replaceFirst(
                  RegExp(r'\.[a-zA-Z]{2,5}$|\.$|$'),
                  '.pdf',
                );
              }
            });
          },
        ),
      ),
    );
    if (_downloadUrl.isNotEmpty) {
      children.add(
        FileDisplayBar(
          fileName: _controller.text,
          maxLines: 2,
          onPress: () async {
            gotoViewPdfUrl(
              _downloadUrl,
              downloadable: true,
              filename: _controller.text,
            );
          },
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget? _buildBottomBar() {
    if (!_canConvert) return null;
    return BottomAppBar(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      color: bgColorLight60,
      child: ElevatedButton(
        onPressed: () async {
          if (_selectedFile == null) {
            await showToast(msg: "暂未未选择文件");
            return;
          }
          _submitFile();
        },
        style: ElevatedButton.styleFrom(
          side: BorderSide(color: mainColorPurple80, width: 2.0),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          "开始转化",
          style: TextStyle(
            color: deepColorPurple,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  void _submitFile() async {
    _message.value = "正在转化";
    showMessageDialog(context, _message);
    String? address;
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        final hash = convertToHash(_selectedFile!.bytes!);
        final previousCheckResult = await ApiAsset.checkPdfExist(address: hash);
        if (previousCheckResult == null) {
          _canConvert = false;
          _downloadUrl = '/asset/pdf/$address';
        }
        final result = await ApiAsset.uploadDocumentConvertToPdf(
          data: _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        );
        if (result is String) return result;
        if (result is Map) {
          address = result.cast<String, String>()['address'];
        }
        if (address == null) return '转化失败';
        return await Future(() async {
          bool flag = true;
          String? checkResult;
          Future.delayed(Duration(minutes: 5)).then((_) {
            flag = false;
          });
          while (flag) {
            checkResult = await ApiAsset.checkPdfExist(address: address!);
            if (checkResult == null) return null;
            await Future.delayed(Duration(seconds: 5));
          }
          return checkResult;
        });
      }),
      initMessageList: [],
      messageList: ["转化文件中，请耐心等待.", "转化文件中，请耐心等待..", "转化文件中，请耐心等待..."],
      successMessage: "转化文件成功",
    );
    Navigator.of(context).pop();
    if (success && address is String) {
      _canConvert = false;
      _downloadUrl = '/asset/pdf/$address';
      setState(() {});
    } else {
      _canConvert = true;
    }
  }
}
