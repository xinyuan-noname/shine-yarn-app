import 'package:flutter/material.dart';
import 'package:shine/cache/user_cache.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/models/to_do_item_data.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_message.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/async_utils.dart';
import 'package:shine/utils/debouncer_utils.dart';
import 'package:shine/utils/message_utils.dart';

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
  }

  Future<void> _handleArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ToDoPageArgs) {
      if (!mounted) return;
      _previousData = args.data;
      _itemId = args.data.itemId;
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
    );
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

  Widget _buildBottomBar() {
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
      if (_previousData!.title != title) {
        WsTask.sendRemind(
          msg: "代办事项“${_previousData?.title}”已更名为“$title”",
          targetList: UserCache.getIdList(),
        );
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
      Navigator.of(context).pop();
      WsTask.sendRemind(
        msg: "收到由「${ApiService.position}」创建的待办事项",
        targetList: UserCache.getIdList(),
      );
    }
  }
}

class ToDoPageArgs {
  final ToDoItemData data;
  const ToDoPageArgs({required this.data});
}
