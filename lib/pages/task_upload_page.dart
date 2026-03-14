import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/custom_back_handler.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/task.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/image.dart';
import 'package:shine/utils/share.dart';

class TaskUploadPage extends StatefulWidget {
  const TaskUploadPage({super.key});

  @override
  State<TaskUploadPage> createState() => _TaskUploadPageState();
}

class _TaskUploadPageState extends State<TaskUploadPage> {
  final GlobalKey _key = GlobalKey();
  int? _taskId;
  String _title = "作业提交";

  String _selectedMimeType = "";
  String _taskName = "";
  String _subject = "";
  final TextEditingController _uploadTitleController = TextEditingController();

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
                        children: [_buildVotingWidget(), Container()],
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

  Widget _buildVotingWidget() {
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
              controller: _uploadTitleController,
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
            Text("科目:", style: labelStyle),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue v) async {
                return [];
              },
              fieldViewBuilder:
                  (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    return TextField(
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 2),
                        hintText: "请输入本次作业的科目",
                        hintStyle: TextStyle(
                          fontFamily: "SmileySans",
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      controller: _uploadTitleController,
                      textAlign: TextAlign.start,
                      style: labelStyle,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      onChanged: (value) {
                        _subject = value;
                      },
                    );
                  },
            ),
            bottomLineSmall,
            Text("格式:", style: labelStyle),
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
          ],
        ),
      ),
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
}
