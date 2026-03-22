import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/file_display_bar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_task_upload.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/async_utils.dart';
import 'package:shine/utils/debouncer_utils.dart';
import 'package:shine/utils/file_utils.dart';
import 'package:shine/utils/message_utils.dart';
import 'package:shine/utils/time_utils.dart';
import 'package:shine/utils/upload_utils.dart';

class NoticeUploadPage extends StatefulWidget {
  const NoticeUploadPage({super.key});

  @override
  State<NoticeUploadPage> createState() => _NoticeUploadPageState();
}

class _NoticeUploadPageState extends State<NoticeUploadPage> {
  UploadTaskStorageData? _data;
  UploadData? _uploadData;
  String _id = "";
  String _class = "";
  String _username = "";
  String _major = "";
  String _academy = "";
  PlatformFile? _selectedFile;
  final _controller = TextEditingController(text: "");
  final _fileNameDebouncer = Debouncer();
  final _filePickerDebouncer = Debouncer();
  final ValueNotifier<String> _message = ValueNotifier("");
  RegExp? _fileNamePattern;
  String? _defaultFileName;
  bool _fileNameEditable = false;
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  _init() async {
    AsyncUtils.postFrame(_handleArgs);
    await _parseFormat();
    if (_defaultFileName is String) {
      _controller.text = _defaultFileName!;
    }
    if (_uploadData != null) {
      _controller.text = _uploadData!.uploadFileName;
    }
  }

  Future<void> _handleArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is NoticeUploadPageArgs) {
      _data = args.data;
      _uploadData = args.uploadData;
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _parseFormat() async {
    if (_data == null) return;
    _username = await ProfileStorage.getName();
    _major = await ProfileStorage.getMajor();
    _academy = await ProfileStorage.getAcademy();
    _class = await ProfileStorage.getClass();
    _id = await ProfileStorage.getId();
    final pattern = RegExp(r'%tag\[([a-z]+)\]%|([^%]+)');
    final matches = pattern.allMatches(_data!.format);
    final List<String> result = [];
    final List<String> rawResult = [];
    for (final match in matches) {
      final tagKey = match.group(1);
      final textContent = match.group(2);
      if (tagKey is String) {
        switch (tagKey) {
          case "academy":
            result.add(RegExp.escape(_academy));
            rawResult.add(_academy);
            break;
          case "username":
            result.add(RegExp.escape(_username));
            rawResult.add(_username);
            break;
          case "major":
            result.add(RegExp.escape(_major));
            rawResult.add(_major);
            break;
          case "class":
            result.add(RegExp.escape(_class));
            rawResult.add(_class);
            break;
          case "id":
            result.add(RegExp.escape(_id));
            rawResult.add(_id);
            break;
          case "free":
            result.add('.*?');
            rawResult.add("xxx");
            _fileNameEditable = true;
            break;
        }
      }
      if (textContent is String) {
        result.add(RegExp.escape(textContent));
        rawResult.add(textContent);
      }
    }
    result.add(r"\..*");
    final recommondExt = getExtensionListFromMimeType(
      _data!.mimetype,
    )?.firstOrNull;
    if (recommondExt == null) {
      rawResult.add(".*");
    } else {
      rawResult.add(recommondExt);
    }
    _fileNamePattern = RegExp(result.join(""));
    _defaultFileName = rawResult.join("");
  }

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

  Widget _buildBodyContent() {
    if (_data == null) {
      return SizedBox();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _data!.title,
          style: const TextStyle(fontFamily: 'SmileySans', fontSize: 24),
        ),
        bottomLine,
        Text(
          "科目：${_data?.subjectName}",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 16,
            color: mainColorRed,
          ),
        ),
        SizedBox(height: 5),
        Text(
          "截止时间：${getLocalTimeString(_data!.endedAt)}(${getDayDifferenceString(_data!.endedAt)})",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 16,
            color: mainColorPurple,
          ),
        ),
        SizedBox(height: 5),
        bottomLineSmall,
        Text(
          "文件名：",
          style: const TextStyle(fontFamily: 'SmileySans', fontSize: 16),
        ),
        Transform.translate(
          offset: Offset(-5, 0),
          child: TextField(
            maxLines: 2,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(0),
              focusedBorder: OutlineInputBorder(),
            ),
            style: const TextStyle(
              fontFamily: 'SmileySans',
              fontSize: 16,
              color: Colors.grey,
            ),
            controller: _controller,
            enabled: _fileNameEditable,
            onChanged: (value) {
              if (_fileNamePattern != null) {
                _fileNameDebouncer.run(() {
                  if (!_fileNamePattern!.hasMatch(_controller.text)) {
                    _controller.text = _defaultFileName ?? "";
                  }
                });
              }
            },
          ),
        ),
        bottomLineSmall,
        SizedBox(height: 5),
        _buildFilePart(),
      ],
    );
  }

  Widget _buildFilePart() {
    final List<Widget> children = [];
    String? fileName;
    int? fileSize;
    if (_selectedFile != null) {
      fileName = _controller.text;
      fileSize = _selectedFile?.bytes?.length;
    } else if (_uploadData != null) {
      fileName = _uploadData!.uploadFileName;
    }
    if (fileName is String) {
      children.add(
        FileDisplayBar(
          fileName: fileName,
          fileSize: fileSize,
          onPress: () async {
            if (_selectedFile is PlatformFile) {
              if (fileName!.endsWith(".pdf")) {
                gotoViewPdfFile(_selectedFile!.path as String);
              } else if (isImageFile(fileName)) {
                gotoViewImageFile(_selectedFile!.path as String);
              } else if (isDocument(fileName)) {
                showToast(msg: "请提交后再查看");
              }
            } else {
              final taskId = _data!.id;
              if (fileName!.endsWith(".pdf")) {
                gotoViewPdfUrl(
                  "/task/upload/file/$taskId/${ApiService.userId}",
                  downloadable: true,
                  filename: fileName,
                );
              } else if (isImageFile(fileName)) {
                gotoViewImageUrl(
                  "/task/upload/file/$taskId/${ApiService.userId}",
                  downloadable: true,
                  filename: fileName,
                );
              } else if (isDocument(fileName)) {
                gotoViewPdfUrl(
                  "/task/upload/view/document/$taskId/${ApiService.userId}",
                  downloadable: true,
                  downloadUrl: "/task/upload/file/$taskId/${ApiService.userId}",
                  filename: fileName,
                );
              } else {
                showToast(msg: "暂不支持预览");
              }
            }
          },
        ),
      );
    }
    children.add(
      InkWell(
        onTap: () {
          _filePickerDebouncer.run(() async {
            if (_data == null) return;
            final exts = getExtensionListFromMimeType(_data!.mimetype);
            PlatformFile? file = exts == null
                ? await pickFileAny()
                : await pickFile(exts: exts);
            if (file == null || file.bytes == null) return;
            _selectedFile = file;
            if (file.extension is String) {
              if (_defaultFileName is String) {
                final pp = _defaultFileName?.lastIndexOf(".");
                if (pp != -1) {
                  _defaultFileName =
                      '${_defaultFileName?.substring(0, pp)}.${file.extension}';
                }
              }
              final p = _controller.text.lastIndexOf('.');
              if (p != -1) {
                _controller.text =
                    '${_controller.text.substring(0, p)}.${file.extension}';
              }
              setState(() {});
            }
          });
        },
        child: Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            border: Border.all(color: mainColorGrey20),
            gradient: whiteLinearGradient,
          ),
          child: Icon(
            fileName == null ? Icons.add : Icons.sync,
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text("作业上传", style: titleTextStyle),
      centerTitle: true,
      bottom: bottomLine,
    );
  }

  Widget _buildBottomBar() {
    final bool edited = _uploadData != null;
    return BottomAppBar(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      color: bgColorLight60,
      child: ElevatedButton(
        onPressed: edited
            ? () async {
                if (_selectedFile == null) {
                  await showToast(msg: "暂未修改文件");
                  return;
                }
                _submitFile();
              }
            : () async {
                if (_selectedFile == null) {
                  await showToast(msg: "你暂未选择上传文件");
                  return;
                }
                _submitFile();
              },
        style: ElevatedButton.styleFrom(
          side: BorderSide(
            color: edited ? deepColorBlue80 : mainColorPurple80,
            width: 2.0,
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          edited ? "提交修改" : "提交作业",
          style: TextStyle(
            color: edited ? deepColorBlue : deepColorPurple,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  Future _submitFile() async {
    _message.value = "正在提交";
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return await ApiTaskUpload.upload(
          _selectedFile!.bytes!,
          filename: _controller.text,
          taskId: _data!.id,
        );
      }),
      initMessageList: [],
      messageList: ["提交文件中.", "提交文件中..", "提交文件中..."],
      successMessage: "提交文件成功",
    );
    Navigator.of(context).pop();
    if (success) {
      Navigator.of(context).pop();
    }
  }
}

class NoticeUploadPageArgs {
  final UploadTaskStorageData data;
  final UploadData? uploadData;
  const NoticeUploadPageArgs({required this.data, this.uploadData});
}
