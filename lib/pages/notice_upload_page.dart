import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/debouncer.dart';
import 'package:shine/utils/time.dart';

class NoticeUploadPage extends StatefulWidget {
  const NoticeUploadPage({super.key});

  @override
  State<NoticeUploadPage> createState() => _NoticeUploadPageState();
}

class _NoticeUploadPageState extends State<NoticeUploadPage> {
  UploadTaskStorageData? _data;
  String _id = "";
  String _class = "";
  String _username = "";
  String _major = "";
  String _academy = "";
  final _controller = TextEditingController(text: "");
  final _fileNameDebouncer = Debouncer();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleArgs();
    });
    await _parseFormat();
    if (_defaultFileName is String) {
      _controller.text = _defaultFileName!;
    }
  }

  Future<void> _handleArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is NoticeUploadPageArgs) {
      _data = args.data;
      setState(() {});
    }
    _parseFormat();
  }

  RegExp? _fileNamePattern;
  String? _defaultFileName;

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
        result.add(tagKey);
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
            break;
        }
      }
      if (textContent is String) {
        result.add(RegExp.escape(textContent));
        rawResult.add(textContent);
      }
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
        bottomLineLarge,
        Text(
          "科目：${_data?.subjectName}",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 16,
            color: mainColorRed,
          ),
        ),
        Text(
          "截止时间：${getLocalTimeString(_data!.endedAt)}(${getDayDifferenceString(_data!.endedAt)})",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 16,
            color: mainColorPurple,
          ),
        ),
        bottomLine,
        TextField(
          controller: _controller,
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
      ],
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
    return BottomAppBar(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      color: bgColorLight60,
      child: ElevatedButton(
        onPressed: () async {},
        style: ElevatedButton.styleFrom(
          side: BorderSide(color: mainColorPurple80, width: 2.0),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: const Text(
          "提交",
          style: TextStyle(
            color: deepColorPurple,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

class NoticeUploadPageArgs {
  final UploadTaskStorageData data;
  const NoticeUploadPageArgs({required this.data});
}
