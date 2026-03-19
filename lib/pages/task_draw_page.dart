import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/cache/user_cache.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/custom_back_handler.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/dual_column_list.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/task.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/components/user_info_bar.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/image.dart';
import 'package:shine/utils/share.dart';

class TaskDrawPage extends StatefulWidget {
  const TaskDrawPage({super.key});

  @override
  State<TaskDrawPage> createState() => _TaskDrawPageState();
}

class _TaskDrawPageState extends State<TaskDrawPage> {
  int? _taskId;
  String _title = "随机选人";
  bool _reproducible = false;
  final TextEditingController _drawNumberController = TextEditingController(
    text: "1",
  );
  final List<Map<String, dynamic>> _allUserList = UserCache.getUserList();
  final List<Map<String, dynamic>> _inRangeUserList = [];
  List<Map<String, dynamic>> get _outRangeUserList => _allUserList
      .where(
        (user) => !_inRangeUserList.any((userIn) {
          return user["id"] == userIn["id"];
        }),
      )
      .toList();

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

  final GlobalKey _key = GlobalKey();
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
    });
  }

  Future<void> _handleArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is TaskDrawPageArgs) {
      final groupStorageKey = args.groupStorageKey;
      if (groupStorageKey is GroupStorageKey) {
        final result = await GroupStorage.getGroupUserList(groupStorageKey);
        if (result is List<Map<String, dynamic>>) {
          _inRangeUserList.clear();
          _inRangeUserList.addAll(result);
          setState(() {});
        }
      }
    }
  }

  void _correctValue() {
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
  }

  @override
  Widget build(BuildContext context) {
    return CustomBackHandler(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          _correctValue();
        },
        child: RepaintBoundary(
          key: _key,
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
                        children: [_buildDrawingWidget(), _buildRangeWidget()],
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
                  Map user = _allUserList.firstWhere(
                    (ele) => ele["id"] == id,
                  );
                  String username = user["username"];
                  return SizedBox(
                    width: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NetworkAvatar(id: id, radius: 25),
                        Text(
                          username,
                          style: const TextStyle(
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
                        "第${_drawResult.length - i}次抽取结果(${avatarList.length}人)",
                        style: expansionListTitleStyle,
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
                        child: Text(
                          "成员可重复(余:${_remainingIdList.length}人)",
                          style: labelStyle,
                        ),
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

  Widget _buildRangeWidget() {
    return DualColumnList(
      leftTitle: "能抽到的同学",
      rightTitle: "不被抽到的同学",
      leftItems: _inRangeUserList,
      rightItems: _outRangeUserList,
      leftItemBuilder: (context, item, index) {
        final id = item["id"];
        final username = item["username"];
        if (id is String && username is String) {
          return UserInfoBar(
            id: id,
            username: username,
            onTap: () {
              _inRangeUserList.remove(item);
              setState(() {});
            },
          );
        }
              return null;
      },
      rightItemBuilder: (context, item, index) {
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
              _inRangeUserList.add(item);
              setState(() {});
            },
          );
        }
              return null;
      },
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
                if (result == null) return;
                try {
                  await WsTask.sendRemind(
                    msg: result,
                    targetList: _selectedIdList,
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

  void _performDraw() {
    int drawNumber = int.tryParse(_drawNumberController.text) ?? 1;

    List<String> availableIds = _reproducible
        ? _inRangeUserIdList
        : _remainingIdList;

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
