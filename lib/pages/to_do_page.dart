import 'package:flutter/material.dart';
import 'package:shine/cache/user_cache.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/models/to_do_item_data.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_message.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/storage/subject_storage.dart';
import 'package:shine/storage/to_do_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/async_utils.dart';
import 'package:shine/utils/debouncer_utils.dart';
import 'package:shine/utils/message_utils.dart';
import 'package:shine/utils/to_do_subject_utils.dart';

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
  }

  Future<void> _handleArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ToDoPageArgs) {
      if (!mounted) return;
      _previousData = args.data;
      _itemId = args.data.itemId;
      _titleController.text = args.data.title;
      _contentController.text = args.data.content;
      setState(() {});
    }
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
    if (ApiService.position == null) {
      showToast(msg: "没有职务的同学不能创建事项");
      return;
    }
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
          readOnly: ApiService.position == null,
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
            readOnly: ApiService.position == null,
            textAlign: TextAlign.start,
            style: textFieldSmallStyle,
            controller: _contentController,
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomBar() {
    if (ApiService.position == null) return null;
    return BottomAppBar(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      color: bgColorLight60,
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
    _message.value = "";
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return _itemId == null
            ? await ApiMessage.addPublicToDoItem(title: title, content: content)
            : await ApiMessage.updatePublicToDoItem(
                itemId: _itemId!,
                title: title,
                content: content,
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
      WsTask.sendRemind(
        msg: "收到由「${ApiService.position}」创建的待办事项「$title」。\n$content",
        targetList: UserCache.getIdList(),
      );
    }
  }
}

class ToDoPageArgs {
  final ToDoItemData data;
  const ToDoPageArgs({required this.data});
}
