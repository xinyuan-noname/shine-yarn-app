import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/user_info_bar.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';

const _titlePadding = EdgeInsets.only(left: 15);

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
    if (args is TaskCheckArgs) {
      final groupStorageKey = args.groupStorageKey;
      final data = args.data;
      if (groupStorageKey is GroupStorageKey) {
        final result = await GroupStorage.getGroupUserList(groupStorageKey);
        if (result is List) {
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!mounted) return;
        const min = 2;
        const max = 8;
        if (_unselectedList.isNotEmpty && _taskId == null) {
          final title = await showPromptDialog(
            context: context,
            title: "该任务暂未完成，是否保存？(名称在$min到$max个字符之间)",
            label: "任务名称",
            confirmText: "保存",
            cancelText: "退出",
            min: min,
            max: max,
            initValue: '',
          );
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
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBodyContent(),
        bottomNavigationBar: _buildBottomBar(),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  padding: _titlePadding,
                  decoration: BoxDecoration(
                    gradient: purpleLinearGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                  ),
                  child: Text(
                    "未完成的同学(${_unselectedList.length})",
                    style: listTitleStyle,
                  ),
                ),
                SizedBox(height: 1),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 16),
                    child: ListView.builder(
                      itemCount: _unselectedList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final unselectedItem = _unselectedList[index];
                        if (unselectedItem is Map) {
                          final id = unselectedItem["id"];
                          final username = unselectedItem["username"];
                          if (id is String && username is String) {
                            return UserInfoBar(
                              id: id,
                              username: username,
                              onTap: () {
                                _unselectedList.remove(unselectedItem);
                                _selectedList.add(unselectedItem);
                                setState(() {});
                              },
                            );
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 2, color: const Color.fromRGBO(189, 189, 189, 0.6)),
          Expanded(
            child: Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  padding: _titlePadding,
                  decoration: BoxDecoration(
                    color: mainColorPurple,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                  ),
                  child: Text(
                    "已完成的同学(${_selectedList.length})",
                    style: listTitleStyle,
                  ),
                ),
                SizedBox(height: 1),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ListView.builder(
                      itemCount: _selectedList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final selectedItem = _selectedList[index];
                        if (selectedItem is Map) {
                          final id = selectedItem["id"];
                          final username = selectedItem["username"];
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
                                _selectedList.remove(selectedItem);
                                _unselectedList.add(selectedItem);
                                setState(() {});
                              },
                            );
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        height: 48,
        padding: EdgeInsets.all(3),
        color: bgColorLight60,
        child: _unselectedList.isNotEmpty
            ? Container(
                width: 100,
                alignment: Alignment.center,
                child: GestureDetector(
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
                    await WsTask.sendRemind(msg: result, targetList: list);
                    print("交换完成");
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: redLinearGradient,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      border: Border.all(color: mainColorPurple),
                    ),
                    padding: EdgeInsets.all(5),
                    child: Text(
                      "一键提醒未完成同学",
                      style: const TextStyle(
                        fontFamily: "SmileySans",
                        fontSize: 16,
                        color: bgColorLight,
                      ),
                    ),
                  ),
                ),
              )
            : SizedBox(),
      ),
    );
  }
}

class TaskCheckArgs {
  final CheckTaskStorageData? data;
  final GroupStorageKey? groupStorageKey;
  const TaskCheckArgs({this.groupStorageKey, this.data});
}
