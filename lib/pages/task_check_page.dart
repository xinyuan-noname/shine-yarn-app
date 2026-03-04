import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/user_info_bar.dart';
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
  int? taskId;
  String _name = "清查任务";
  final List _unselectedList = [];
  final List _selectedList = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleArgs();
  }

  Future<void> _handleArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is TaskCheckArgs) {
      final groupStorageKey = args.groupStorageKey;
      final id = args.id;
      if (groupStorageKey is GroupStorageKey) {
        final result = await GroupStorage.getGroupUserList(groupStorageKey);
        if (result is List) {
          _unselectedList.addAll(result);
          setState(() {});
        }
      }
      if (id is String) {}
    }
  }

  Future<void> _saveOnPop() async {
    final title = await showPromptDialog(
      context: context,
      title: "是否保存？是，则为本次任务命名；否，则点击取消。",
      label: "任务名称",
    );
    if (title is String) {
      await TaskStorage.addCheckTask(
        title: title,
        finished: _selectedList,
        unfinished: _unselectedList,
      );
    } else {
      final result = await showConfrimDialog(
        context: context,
        title: "确认退出吗？",
        content: "该操作会丢失所有数据",
      );
      if (result == false) {
        await _saveOnPop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!mounted) return;
        if (taskId == null) {
          await _saveOnPop();
        }
        if (_unselectedList.isEmpty && taskId != null) {
          await TaskStorage.delCheckTask(id: taskId!);
          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_name, style: titleTextStyle),
          centerTitle: true,
          bottom: bottomLine,
          actions: [
            IconButton(
              onPressed: () async {
                final result = await showPromptDialog(
                  context: context,
                  title: "请输入更改任务名",
                  label: "更改后的任务名",
                  initValue: _name,
                );
                if (result is String) {
                  _name = result;
                  setState(() {});
                }
              },
              icon: Icon(Icons.edit, size: 28),
            ),
          ],
        ),
        body: _buildBodyContent(),
      ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10),
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
                              ),
                              usernameStyle: const TextStyle(
                                fontFamily: "SmileySans",
                                color: Colors.grey,
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
}

class TaskCheckArgs {
  final int? id;
  final GroupStorageKey? groupStorageKey;
  const TaskCheckArgs({this.groupStorageKey, this.id});
}
