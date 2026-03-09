import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/extensions/list.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/theme.dart';

class TaskDrawPage extends StatefulWidget {
  const TaskDrawPage({super.key});

  @override
  State<TaskDrawPage> createState() => _TaskDrawPageState();
}

class _TaskDrawPageState extends State<TaskDrawPage> {
  int? _taskId;
  String _title = "清查任务";
  bool _reproducible = false;
  final TextEditingController _drawNumberController = TextEditingController(
    text: "1",
  );
  final List _allUserList = [];
  final List _inRangeUserList = [];
  List get _outRangeUserList =>
      _allUserList.where((user) => !_inRangeUserList.contains(user)).toList();

  final List<List<String>> _drawResult = [];
  List<List<String>> get _drawResultReversed => _drawResult.reversed.toList();

  List<String> get _inRangeUserIdList => _inRangeUserList
      .whereType<Map<String, dynamic>>()
      .map((ele) => ele['id'])
      .whereType<String>()
      .toList();
  List<String> get _selectedIdList =>
      _drawResult.expand((sublist) => sublist).toSet().toList();
  List<String> get _remainingIdList =>
      _inRangeUserIdList.where((id) => !_selectedIdList.contains(id)).toList();

  int get _maxDrawLength =>
      _reproducible ? _inRangeUserIdList.length : _remainingIdList.length;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _drawNumberController.dispose();
    super.dispose();
  }

  Future _init() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _handleArgs();
      print(_inRangeUserList);
      print(_inRangeUserList.whereType<Map<String, dynamic>>());
    });
    final allUserOrNull = await GroupStorage.getGroupUserList(
      GroupStorageKey.entire,
    );
    if (allUserOrNull is List) {
      _allUserList.addAll(allUserOrNull);
    }
  }

  Future<void> _handleArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is TaskDrawPageArgs) {
      final groupStorageKey = args.groupStorageKey;
      if (groupStorageKey is GroupStorageKey) {
        final result = await GroupStorage.getGroupUserList(groupStorageKey);
        if (result is List) {
          _inRangeUserList.clear();
          _inRangeUserList.addAll(result);
          setState(() {});
        }
      }
      // if (data is CheckTaskStorageData) {
      //   final finishedList = data.finished;
      //   final unfinishedList = data.unfinished;
      //   _taskId = data.id;
      //   _title = data.title;
      //   _selectedList.clear();
      //   _selectedList.addAll(finishedList);
      //   _unselectedList.clear();
      //   _unselectedList.addAll(unfinishedList);
      //   setState(() {});
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        int? currentValue = int.tryParse(_drawNumberController.text);
        if (currentValue == null) {
          _drawNumberController.text = '1';
          return;
        }
        if (currentValue < 1) {
          _drawNumberController.text = '1';
        }
        if (currentValue > _maxDrawLength) {
          _drawNumberController.text = _maxDrawLength.toString();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: DefaultTabController(
          length: 2,
          child: SafeArea(
            child: Column(
              children: [
                TabBar(
                  tabs: [Text("进行抽取"), Text("抽取范围")],
                  labelStyle: tabLabelStyle,
                  padding: EdgeInsets.only(top: 2),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildDrawingWidget(),
                      Container(
                        padding: bodyPadding,
                        child: Center(child: Text('Page 2')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildDrawingWidget() {
    return Container(
      padding: bodyPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _drawResult.length,
              itemBuilder: (BuildContext context, int i) {
                final list = _drawResultReversed[i];
                final avatarList = List.generate(list.length, (index) {
                  String id = list[index];
                  Map user = _allUserList.firstWhere((ele) => ele["id"] == id);
                  String username = user["username"];
                  return SizedBox(
                    width: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NetworkAvatar(id: id, radius: 25),
                        Text(
                          username,
                          style: TextStyle(
                            fontFamily: "SmileySans",
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                });
                return Column(
                  children: [
                    ExpansionTile(
                      initiallyExpanded: i == 0,
                      title: Text(
                        "第${_drawResult.length - i}次抽取结果",
                        style: listTitlePurpleStyle,
                      ),
                      children: [
                        Wrap(direction: Axis.horizontal, children: avatarList),
                      ],
                    ),
                    SizedBox(width: 10),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 5),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      int? currentValue = int.tryParse(
                        _drawNumberController.text,
                      );
                      if (currentValue == null) {
                        _drawNumberController.text = '1';
                        return;
                      }
                      if (currentValue > 1) {
                        _drawNumberController.text = (currentValue - 1)
                            .toString();
                      }
                    },
                    icon: Icon(Icons.remove),
                  ),
                  InkWell(
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: mainColorPurple,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text("抽取", style: purpleButtonStyle),
                          SizedBox(
                            width: 35,
                            child: TextField(
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(0),
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                              controller: _drawNumberController,
                              textAlign: TextAlign.center,
                              style: purpleButtonStyle,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          Text("人", style: purpleButtonStyle),
                        ],
                      ),
                    ),
                    onTap: () {
                      _performDraw();
                    },
                  ),
                  IconButton(
                    onPressed: () {
                      int? currentValue = int.tryParse(
                        _drawNumberController.text,
                      );
                      if (currentValue == null) {
                        _drawNumberController.text = '1';
                        return;
                      }
                      if (currentValue < _maxDrawLength) {
                        _drawNumberController.text = (currentValue + 1)
                            .toString();
                      }
                    },
                    icon: Icon(Icons.add),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _reproducible,
                        onChanged: (bool? value) {
                          _reproducible = !_reproducible;
                          setState(() {});
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          _reproducible = !_reproducible;
                          setState(() {});
                        },
                        child: Text("成员可重复"),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _performDraw() {
    int drawNumber = int.tryParse(_drawNumberController.text) ?? 1;

    List<String> availableIds = _reproducible
        ? _inRangeUserIdList
        : _remainingIdList;

    // 确保抽取人数不超过可用人数
    if (drawNumber > availableIds.length) {
      drawNumber = availableIds.length;
    }

    if (drawNumber <= 0 || availableIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('没有足够的用户可供抽取')));
      return;
    }

    final random = Random();
    final shuffledIds = availableIds.toList()..shuffle(random);
    final drawnIds = shuffledIds.take(drawNumber).toList();
    _drawResult.add(drawnIds);

    setState(() {});
  }
}

class TaskDrawPageArgs {
  final GroupStorageKey? groupStorageKey;
  const TaskDrawPageArgs({this.groupStorageKey});
}
