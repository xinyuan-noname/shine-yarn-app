import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shine/components/custom_back_handler.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/dual_column_list.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/task.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/components/user_info_bar.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/image.dart';
import 'package:shine/utils/share_utils.dart';


class TaskCheckPage extends StatefulWidget {
  const TaskCheckPage({super.key});

  @override
  State<TaskCheckPage> createState() => _TaskCHeckPageState();
}

class _TaskCHeckPageState extends State<TaskCheckPage> {
  int? _taskId;
  String _title = "清查任务";
  final List _unselectedList = [];
  final List _selectedList = [];
  final GlobalKey _key = GlobalKey();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleArgs();
    });
  }

  Future<void> _handleArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is TaskCheckPageArgs) {
      final groupStorageKey = args.groupStorageKey;
      final data = args.data;
      if (groupStorageKey is GroupStorageKey) {
        final result = await GroupStorage.getGroupUserList(groupStorageKey);
        if (result is List<Map<String, dynamic>>) {
          _unselectedList.clear();
          _unselectedList.addAll(result);
          setState(() {});
        }
      }
      if (data is CheckTaskStorageData) {
        final finishedList = data.finished;
        final unfinishedList = data.unfinished;
        _taskId = data.id;
        _title = data.title;
        _selectedList.clear();
        _selectedList.addAll(finishedList);
        _unselectedList.clear();
        _unselectedList.addAll(unfinishedList);
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBackHandler(
      onWillPop: () async {
        if (_unselectedList.isNotEmpty && _taskId == null) {
          final title = await showUnfinishedTaskSaveDialog(context: context);
          if (title is String) {
            await TaskStorage.addCheckTask(
              title: title,
              finished: _selectedList,
              unfinished: _unselectedList,
            );
          }
        } else if (_taskId != null) {
          if (_unselectedList.isEmpty) {
            await TaskStorage.delCheckTask(id: _taskId!);
          } else {
            await TaskStorage.updateCheckTask(
              id: _taskId!,
              title: _title,
              finished: _selectedList,
              unfinished: _unselectedList,
            );
          }
        }
        return true;
      },
      child: RepaintBoundary(
        key: _key,
        child: Scaffold(
          appBar: _buildAppBar(),
          body: (_buildBodyContent()),
          bottomNavigationBar: _buildBottomBar(),
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
                await TaskStorage.updateCheckTask(id: _taskId!, title: result);
                _title = result;
                setState(() {});
              }
            },
            icon: Icon(Icons.edit, size: 28),
          ),
      ],
    );
  }

  Widget _buildBodyContent() {
    return SafeArea(
      child: DualColumnList(
        leftTitle: "未完成的同学",
        rightTitle: "已完成的同学",
        leftItems: _unselectedList,
        rightItems: _selectedList,
        leftItemBuilder: (context, item, index) {
          if (item is Map<String, dynamic>) {
            final id = item["id"];
            final username = item["username"];
            if (id is String && username is String) {
              return UserInfoBar(
                id: id,
                username: username,
                onTap: () {
                  _unselectedList.remove(item);
                  _selectedList.add(item);
                  setState(() {});
                  if (_unselectedList.isEmpty) {
                    showToast(msg: "任务($_title)完成");
                  }
                },
                onDismissed: (direction) {
                  _unselectedList.remove(item);
                  setState(() {});
                  if (_unselectedList.isEmpty) {
                    showToast(msg: "任务($_title)完成");
                  }
                },
              );
            }
          }
          return null;
        },
        rightItemBuilder: (context, item, index) {
          if (item is Map<String, dynamic>) {
            final id = item["id"];
            final username = item["username"];
            if (id is String && username is String) {
              return UserInfoBar(
                id: id,
                username: username,
                idStyle: const TextStyle(
                  fontFamily: "SmileySans",
                  color: Colors.grey,
                  fontSize: 15,
                ),
                usernameStyle: const TextStyle(
                  fontFamily: "SmileySans",
                  color: Colors.grey,
                  fontSize: 15,
                ),
                onTap: () {
                  _selectedList.remove(item);
                  _unselectedList.add(item);
                  setState(() {});
                },
                onDismissed: (direction) {
                  _selectedList.remove(item);
                  setState(() {});
                },
              );
            }
          }
          return null;
        },
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
        child: _unselectedList.isNotEmpty
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildBottomItem(
                    onTap: () async {
                      final result = await showPromptDialog(
                        context: context,
                        title: "请设置提醒消息, 点击确定以发送",
                        label: "提醒消息",
                        initValue: "请尽快完成",
                      );
                      if (result == null) return;
                      final List<String> list = [];
                      for (final unselectedItem in _unselectedList) {
                        final id = unselectedItem["id"];
                        if (id is String) list.add(id);
                      }
                      try {
                        await WsTask.sendRemind(
                          msg: result,
                          targetList: list,
                          level: 4,
                        );
                        showToast(msg: "发送成功");
                      } catch (err) {
                        showToast(msg: "发送失败, ${err.toString()}");
                      }
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
                        name: "check_task.png",
                        title: _title,
                      );
                    },
                    icon: Icons.share_outlined,
                    title: '分享到...',
                  ),
                ],
              )
            : SizedBox(),
      ),
    );
  }
}

class TaskCheckPageArgs {
  final CheckTaskStorageData? data;
  final GroupStorageKey? groupStorageKey;
  const TaskCheckPageArgs({this.groupStorageKey, this.data});
}
