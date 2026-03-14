import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:shine/components/custom_back_handler.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/task.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/storage/subject_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/image.dart';
import 'package:shine/utils/share.dart';

class TaskUploadPage extends StatefulWidget {
  const TaskUploadPage({super.key});

  @override
  State<TaskUploadPage> createState() => _TaskUploadPageState();
}

class _NameNode {
  int _deleteEmptyTimes = 0;
  final bool isText;
  final String value;
  String? content;
  TextEditingController? controller;
  FocusNode? focusNode;
  Function(bool)? onDelete;
  bool get deleteLastNode => _deleteEmptyTimes > 0;
  _NameNode({
    required this.value,
    this.content,
    this.isText = true,
    this.onDelete,
  }) {
    if (isText) {
      controller = TextEditingController(text: content);
      focusNode = FocusNode(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.backspace ||
                event.logicalKey == LogicalKeyboardKey.delete) {
              if (controller!.text.isEmpty) {
                _deleteEmptyTimes++;
              } else {
                _deleteEmptyTimes = 0;
              }
              if (onDelete is VoidCallback) onDelete!(deleteLastNode);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
      );
    }
  }

  dispose() {
    controller?.dispose();
    focusNode?.dispose();
  }
}

class _TaskUploadPageState extends State<TaskUploadPage> {
  final GlobalKey _key = GlobalKey();
  int? _taskId;
  String _title = "作业提交";

  String _selectedMimeType = "";
  String _taskName = "";
  final List<_NameNode> _nameNodeList = [_NameNode(value: "")];
  final List<String> _subjectNameList = [];
  final TextEditingController _subjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future _init() async {
    _subjectNameList.addAll(
      await SubjectStorage.getCurrentSemesterName() ?? [],
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomBackHandler(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: RepaintBoundary(
          key: _key,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: _buildAppBar(),
            body: DefaultTabController(
              length: 2,
              child: SafeArea(
                child: Column(
                  children: [
                    TabBar(
                      tabs: [Text("提交设置"), Text("完成情况")],
                      labelStyle: tabLabelStyle,
                      padding: EdgeInsets.only(top: 2),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [_buildUploadWidget(), Container()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: _buildBottomBar(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_title, style: titleTextStyle),
      centerTitle: true,
      bottom: bottomLine,
      actions: [
        if (_taskId is int)
          IconButton(
            onPressed: () async {
              final result = await showPromptDialog(
                context: context,
                title: "请输入更改任务名",
                label: "更改后的任务名",
                initValue: _title,
              );
              if (result is String) {
                // await TaskStorage.updateCheckTask(id: _taskId!, title: result);
                _title = result;
                setState(() {});
              }
            },
            icon: Icon(Icons.edit, size: 28),
          ),
      ],
    );
  }

  Widget _buildUploadWidget() {
    return Container(
      padding: bodyPadding,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 2),
                hintText: "请输入本次作业提交的标题",
                hintStyle: textFieldHintStyle,
              ),
              textAlign: TextAlign.start,
              style: textFieldStyle,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              onChanged: (value) {
                _taskName = value;
              },
            ),
            const SizedBox(height: 5),
            bottomLine,
            const SizedBox(height: 5),
            Text(
              "科目:",
              style: const TextStyle(fontFamily: "SmileySans", fontSize: 16),
            ),
            TypeAheadField<String>(
              builder: (context, controller, focusNode) {
                return TextField(
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 2),
                    hintText: "请输入科目",
                    hintStyle: const TextStyle(
                      fontFamily: "SmileySans",
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontFamily: "SmileySans",
                    fontSize: 16,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  controller: controller,
                  focusNode: focusNode,
                );
              },
              controller: _subjectController,
              itemBuilder: (context, value) {
                return ListTile(title: Text(value, style: labelStyle));
              },
              onSelected: (value) {
                _subjectController.text = value;
              },
              suggestionsCallback: (search) {
                if (search.isEmpty) return _subjectNameList;
                return _subjectNameList.where((sub) {
                  int i = 0;
                  for (final char in search.split("")) {
                    i = sub.substring(i).indexOf(char);
                    if (i == -1) return false;
                  }
                  return true;
                }).toList();
              },
            ),
            bottomLineSmall,
            const SizedBox(height: 5),
            const Text("格式:", style: labelStyle),
            DropdownButton<String>(
              style: const TextStyle(
                fontFamily: "SmileySans",
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              value: _selectedMimeType,
              items: [
                DropdownMenuItem(value: "", child: Text("不限格式")),
                DropdownMenuItem(
                  value:
                      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                  child: Text("word文档"),
                ),
                DropdownMenuItem(
                  value: "application/pdf",
                  child: Text("pdf文档"),
                ),
                DropdownMenuItem(
                  value:
                      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                  child: Text("excel表格"),
                ),
                DropdownMenuItem(value: "image", child: Text("图片")),
                DropdownMenuItem(value: "image/jpeg", child: Text("jpg图片")),
                DropdownMenuItem(value: "image/png", child: Text("png图片")),
                DropdownMenuItem(value: "video/mp4", child: Text("mp4视频")),
              ],
              onChanged: (String? value) {
                if (value == null) return;
                _selectedMimeType = value;
                setState(() {});
              },
            ),
            bottomLineSmall,
            const SizedBox(height: 5),
            Text(
              "文件名:",
              style: const TextStyle(fontFamily: "SmileySans", fontSize: 16),
            ),
            _buildFileNameWidget(),
            _buildFormationWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileNameWidget() {
    final List<Widget> children = [];
    final List<Widget> wl = List.generate(_nameNodeList.length, (index) {
      final node = _nameNodeList[index];
      if (node.isText) {
        return IntrinsicWidth(
          child: TextField(
            scrollPadding: EdgeInsets.all(0),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(0),
              hintText: index == 0 && _nameNodeList.length == 1
                  ? "请设置文件名"
                  : null,
              hintStyle: const TextStyle(
                fontFamily: "SmileySans",
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            textAlign: TextAlign.start,
            style: const TextStyle(fontFamily: "SmileySans", fontSize: 16),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[\s$\{\}]')),
            ],
            controller: node.controller,
            focusNode: node.focusNode,
          ),
        );
      }
      return GestureDetector(
        child: Container(
          padding: EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: blueLinearGradient,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            node.content ?? "",
            style: const TextStyle(
              fontFamily: "SmileySans",
              fontSize: 16,
              color: bgColorLight,
            ),
          ),
        ),
        onTap: () {
          _nameNodeList.removeRange(index, index + 2);
          setState(() {});
        },
      );
    }).toList();
    children.addAll(wl);
    return GestureDetector(
      onTap: () {
        final last = _nameNodeList.elementAt(_nameNodeList.length - 1);
        if (last.focusNode != null) {
          FocusScope.of(context).unfocus();
          last.focusNode?.requestFocus();
        }
      },
      child: Container(
        padding: EdgeInsets.all(1),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(gradient: whiteLinearGradient),
        child: Row(children: children),
      ),
    );
  }

  final List<List<String>> _formationInfo = [
    ["major", "专业"],
    ["class", "班级"],
    ["username", "姓名"],
    ["id", "学号"],
    ["free", "自由输入"],
  ];
  Widget _buildFormationWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _formationInfo.map((e) {
        return GestureDetector(
          child: Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: blueLinearGradient,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              e[1],
              style: const TextStyle(
                fontFamily: "SmileySans",
                fontSize: 16,
                color: bgColorLight,
              ),
            ),
          ),
          onTap: () {
            final buttonNode = _NameNode(
              value: e[0],
              content: e[1],
              isText: false,
            );
            final textNode = _NameNode(
              value: "",
              onDelete: (f) {
                if (f) {
                  _nameNodeList.remove(buttonNode);
                }
              },
            );
            _nameNodeList.add(buttonNode);
            _nameNodeList.add(textNode);
            setState(() {});
            final last = _nameNodeList.elementAt(_nameNodeList.length - 1);
            if (last.focusNode != null) {
              FocusScope.of(context).unfocus();
              last.focusNode?.requestFocus();
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color.fromRGBO(158, 158, 158, 0.8),
            width: 0.5,
          ),
        ),
      ),
      child: BottomAppBar(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 30),
        color: bgColorLight60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildBottomItem(
              onTap: () async {
                final result = await showPromptDialog(
                  context: context,
                  title: "请设置提醒消息, 点击确定以发送",
                  label: "提醒消息",
                  initValue: "恭喜你被抽中了",
                );
                // if (result == null) return;
                // try {
                //   await WsTask.sendRemind(
                //     msg: result,
                //     targetList: _selectedIdList,
                //     level: 0,
                //   );
                //   showToast(msg: "发送成功");
                // } catch (err) {
                //   showToast(msg: "发送失败, ${err.toString()}");
                // }
              },
              icon: Icons.notifications_outlined,
              title: '一键提醒',
            ),
            buildBottomItem(
              onTap: () async {
                final image = await captureWidgetToPng(globalKey: _key);
                if (image == null) {
                  showToast(msg: "获取屏幕信息失败");
                  return;
                }
                await shareImage(
                  image: image,
                  name: "draw_task.png",
                  title: _title,
                );
              },
              icon: Icons.share_outlined,
              title: '分享到...',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _subjectController.dispose();
    for (final node in _nameNodeList) {
      node.dispose();
    }
  }
}
