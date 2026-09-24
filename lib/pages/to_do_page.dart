import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shine/cache/user_cache.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/pick_image.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/models/to_do_item_data.dart';
import 'package:shine/services/api_asset.dart';
import 'package:shine/services/api_message.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/storage/subject_storage.dart';
import 'package:shine/storage/to_do_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/async_utils.dart';
import 'package:shine/utils/debouncer_utils.dart';
import 'package:shine/utils/link_utils.dart';
import 'package:shine/utils/message_utils.dart';
import 'package:shine/utils/to_do_author_utils.dart';
import 'package:shine/utils/to_do_subject_utils.dart';
import 'package:shine/utils/to_do_viewer.dart';

class ToDoPage extends StatefulWidget {
  const ToDoPage({super.key});

  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  final _titleController = TextEditingController(text: "");
  final _titleDebouncer = Debouncer();
  final _contentController = TextEditingController(text: "");
  final _contentDebouncer = Debouncer();
  final ValueNotifier<String> _message = ValueNotifier("");
  ToDoItemData? _previousData;
  String? _itemId;

  /// 当前用户身份：所有人都能发布事项，发布时用昵称作为来源
  ToDoViewer? _viewer;

  /// 作业模板里可选的科目（课表科目 + 自建科目）
  List<String> _subjectOptions = [];
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    _titleDebouncer.dispose();
    _contentController.dispose();
    _contentDebouncer.dispose();
    _message.dispose();
  }

  void _init() {
    AsyncUtils.postFrame(_handleArgs);
    _loadSubjectOptions();
    _loadViewer();
  }

  Future<void> _loadViewer() async {
    final viewer = await ToDoViewer.load();
    if (!mounted) return;
    setState(() {
      _viewer = viewer;
    });
  }

  Future<void> _handleArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! ToDoPageArgs) return;
    if (!mounted) return;
    // 只有作者和管理员能改别人发的事项，直接进编辑页时补一次校验
    final viewer = _viewer ?? await ToDoViewer.load();
    if (!mounted) return;
    if (!viewer.canOperate(args.data.source)) {
      showToast(msg: "只能编辑自己发布的事项");
      Navigator.of(context).pop();
      return;
    }
    _previousData = args.data;
    _itemId = args.data.itemId;
    _titleController.text = args.data.title;
    _contentController.text = args.data.content;
    setState(() {});
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text("事项编辑", style: titleTextStyle),
      centerTitle: true,
      bottom: bottomLine,
      actions: [
        // 作业事项模板：一键填好标题与内容（含科目、截止时间）
        TextButton.icon(
          onPressed: _applyHomeworkTemplate,
          icon: const Icon(
            Icons.assignment_outlined,
            size: 20,
            color: mainColorLinkBlue,
          ),
          label: const Text(
            "模板",
            style: TextStyle(
              fontFamily: "SmileySans",
              fontSize: 16,
              color: mainColorLinkBlue,
            ),
          ),
        ),
      ],
    );
  }

  /// 选择并上传一张图片，成功后插入到内容的光标位置
  Future<void> _insertImage() async {
    await pickImage(context, (XFile image) async {
      await _uploadAndInsertImage(image);
    });
  }

  Future<void> _uploadAndInsertImage(XFile image) async {
    Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
    } catch (e) {
      showToast(msg: "读取图片失败");
      return;
    }
    if (bytes.isEmpty) {
      showToast(msg: "读取图片失败");
      return;
    }
    if (!mounted) return;

    _message.value = "正在上传图片中";
    showMessageDialog(context, _message);
    String? imageName;
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        final result = await ApiAsset.uploadToDoImage(
          data: bytes,
          filename: image.name,
          mimeType: image.mimeType,
        );
        if (result is String) return result;
        if (result is Map && result["name"] is String) {
          imageName = result["name"] as String;
          return null;
        }
        return "图片上传失败";
      }),
      initMessageList: [],
      messageList: ["正在上传中.", "正在上传中..", "正在上传中..."],
      successMessage: "上传成功",
      successMessageDuration: Duration(milliseconds: 300),
      failMessageDuration: Duration(milliseconds: 900),
    );
    if (mounted) Navigator.of(context).pop();
    if (!success || imageName == null) return;
    _insertContentText(toDoImageToken(imageName!));
    showToast(msg: "已插入图片，保存后所有同学都能看到");
  }

  /// 在内容光标处插入文本，图片标记单独占一行，便于阅读
  void _insertContentText(String text) {
    final value = _contentController.value;
    var selection = value.selection;
    if (!selection.isValid) {
      selection = TextSelection.collapsed(offset: value.text.length);
    }
    final before = value.text.substring(0, selection.start);
    final needsLeadingLine = before.isNotEmpty && !before.endsWith("\n");
    final insert = "${needsLeadingLine ? "\n" : ""}$text\n";
    final newText = value.text.replaceRange(selection.start, selection.end, insert);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + insert.length),
    );
    setState(() {});
  }

  /// 加载可选科目：课表科目 + 自建科目
  Future<void> _loadSubjectOptions() async {
    final names = <String>[];
    names.addAll(await SubjectStorage.getCurrentSubjectName());
    final diyList = await SubjectStorage.getCurrentDiySubjectInfo();
    names.addAll(diyList.map((course) => course.subjectName));
    if (!mounted) return;
    setState(() {
      _subjectOptions = normalizeSubjectList(names);
    });
  }

  /// 套用作业事项模板
  Future<void> _applyHomeworkTemplate() async {
    final result = await showHomeworkTemplateDialog(
      context: context,
      subjectOptions: _subjectOptions,
    );
    if (result == null) return;
    _titleController.text = result.title;
    _contentController.text = result.content;
    setState(() {});
    showToast(msg: "已套用作业模板，可继续修改");
  }

  Widget _buildBodyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 2),
            hintText: "请输入事项的标题",
            hintStyle: textFieldHintStyle,
          ),
          textAlign: TextAlign.start,
          style: textFieldStyle,
          controller: _titleController,
        ),
        bottomLine,
        SizedBox(height: 10),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 2),
              hintText: "请输入事项的内容",
              hintStyle: textFieldHintSmallStyle,
            ),
            keyboardType: TextInputType.multiline,
            maxLines: null,
            textAlign: TextAlign.start,
            style: textFieldSmallStyle,
            controller: _contentController,
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomBar() {
    return BottomAppBar(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      color: bgColorLight60,
      child: Row(
        children: [
          // 插入图片：选图上传后把图片标记插到内容光标处
          TextButton.icon(
            onPressed: _insertImage,
            icon: const Icon(
              Icons.add_photo_alternate_outlined,
              size: 26,
              color: deepColorBlue80,
            ),
            label: const Text(
              "插入图片",
              style: TextStyle(
                fontFamily: "SmileySans",
                color: deepColorBlue80,
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final title = _titleController.text;
                if (title.isEmpty) {
                  showToast(msg: "必须设置事项标题");
                  return;
                }
                _saveToDoItem();
              },
              style: ElevatedButton.styleFrom(
                side: BorderSide(color: deepColorBlue80, width: 2.0),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: const Text(
                "保存事项",
                style: TextStyle(
                  color: deepColorBlue80,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveToDoItem() async {
    final title = _titleController.text;
    final content = _contentController.text;
    if (_previousData != null) {
      if (_previousData!.title == title && _previousData!.content == content) {
        showToast(msg: "该代办项未发生变化");
        return;
      }
    }
    // 所有人都能发布：来源写自己的昵称，改已有事项时保留原作者
    final viewer = _viewer ?? await ToDoViewer.load();
    if (!mounted) return;
    final publisher = viewer.publisherSource;
    final previousSource = _previousData?.source.trim() ?? '';
    final source = previousSource.isNotEmpty ? previousSource : publisher;
    // 管理员改别人的事项时不广播提醒：文案会写成「由我创建」，也没必要惊动全班
    final editedOthers =
        _itemId != null &&
        !isMyToDoItem(
          itemSource: source,
          username: viewer.username,
          position: viewer.position,
          userId: viewer.id,
        );
    _message.value = "";
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return _itemId == null
            ? await ApiMessage.addPublicToDoItem(
                title: title,
                content: content,
                source: source,
              )
            : await ApiMessage.updatePublicToDoItem(
                itemId: _itemId!,
                title: title,
                content: content,
                source: source,
              );
      }),
      initMessageList: [],
      messageList: ["保存待办事项中.", "保存待办事项中..", "保存待办事项中..."],
      successMessage: "保存待办事项成功",
      successMessageDuration: Duration(milliseconds: 300),
      failMessageDuration: Duration(milliseconds: 800),
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    if (success) {
      // 把改动同步进本地缓存，断网时事项表也不会显示旧内容
      final itemId = _itemId;
      if (itemId != null) {
        await ToDoStorage.updateToDoItem(
          itemId: itemId,
          title: title,
          content: content,
        );
      }
      Navigator.of(context).pop();
      // 管理员改别人的事项不广播提醒（作者不是自己，文案会误导）
      if (editedOthers) return;
      // 提醒消息是纯文本，去掉图片标记，只说明事项里有图
      final plainContent = stripToDoImageTags(content);
      final hasImage = plainContent != content;
      final author = publisher.isNotEmpty ? publisher : toDoSourceLabel(source);
      WsTask.sendRemind(
        msg:
            "收到由「$author」创建的待办事项「$title」。\n$plainContent${hasImage ? "\n（本条事项含图片，请在事项表里查看）" : ""}",
        targetList: UserCache.getIdList(),
      );
    }
  }
}

class ToDoPageArgs {
  final ToDoItemData data;
  const ToDoPageArgs({required this.data});
}
