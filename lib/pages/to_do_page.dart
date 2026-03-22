import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/debouncer_utils.dart';

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
  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    _titleDebouncer.dispose();
    _contentController.dispose();
    _contentDebouncer.dispose();
    _message.dispose();
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
          final content = _contentController.text;
          if (title.isEmpty) {
            showToast(msg: "必须设置事项标题");
            return;
          }
          
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
}
