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
import 'package:shine/services/api.dart';
import 'package:shine/services/api_draw.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/async_utils.dart';
import 'package:shine/utils/image_utils.dart';
import 'package:shine/utils/message_utils.dart';
import 'package:shine/utils/share_utils.dart';

class TaskDrawPage extends StatefulWidget {
  const TaskDrawPage({super.key});

  @override
  State<TaskDrawPage> createState() => _TaskDrawPageState();
}

class _TaskDrawPageState extends State<TaskDrawPage> {
  int? _taskId;
  String _title = "随机选人";
  bool _reproducible = false;
  /// 抽取范围或重复设置有过改动, 需要在合适的时机同步到服务端
  bool _dirty = false;
  /// 正在向服务端同步, 避免重复提交
  bool _syncing = false;
  final ValueNotifier<String> _message = ValueNotifier("正在保存中");
  final TextEditingController _drawNumberController = TextEditingController(
    text: "1",
  );
  final List<Map<String, dynamic>> _inRangeUserList = [];

  /// 所有已知用户, 抽取范围可能来自服务端, 这里把两处数据合起来做展示兜底
  List<Map<String, dynamic>> get _allUserList {
    final Map<String, Map<String, dynamic>> merged = {};
    for (final user in UserCache.getUserList()) {
      final id = user["id"];
      if (id is String) merged[id] = user;
    }
    for (final user in _inRangeUserList) {
      final id = user["id"];
      if (id is String) merged[id] = user;
    }
    return merged.values.toList();
  }

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
    await AsyncUtils.postFrame(() async {
      await _handleArgs();
    });
  }

  Future<void> _handleArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! TaskDrawPageArgs) return;
    // 从首页任务卡片打开时, 以服务端数据为准
    final taskId = args.taskId ?? args.data?.id;
    if (taskId is int) {
      await _loadFromServer(taskId);
      return;
    }
    final groupStorageKey = args.groupStorageKey;
    if (groupStorageKey is GroupStorageKey) {
      final result = await GroupStorage.getGroupUserList(groupStorageKey);
      if (result is List<Map<String, dynamic>>) {
        _inRangeUserList.clear();
        _inRangeUserList.addAll(result);
        if (!mounted) return;
        setState(() {});
      }
    }
  }

  /// 加载服务端保存的随机选人任务
  Future<void> _loadFromServer(int taskId) async {
    final result = await ApiDraw.getDrawTask(taskId);
    if (!mounted) return;
    if (result is! Map) {
      if (result is String) showToast(msg: result);
      return;
    }
    _taskId = result["taskId"] is int ? result["taskId"] : taskId;
    if (result["title"] is String) _title = result["title"];
    _reproducible = result["reproducible"] == true;
    _inRangeUserList.clear();
    final rangeUserList = result["rangeUserList"];
    if (rangeUserList is List) {
      _inRangeUserList.addAll(rangeUserList.whereType<Map<String, dynamic>>());
    }
    _drawResult.clear();
    final drawResult = result["drawResult"];
    if (drawResult is List) {
      for (final round in drawResult) {
        if (round is List) {
          _drawResult.add(round.whereType<String>().toList());
        }
      }
    }
    setState(() {});
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

  /// 把当前的范围/结果/设置同步到服务端, 没有任务时先创建
  Future<String?> _syncToServer() async {
    if (_syncing) return null;
    if (_taskId == null && _drawResult.isEmpty) return null;
    _syncing = true;
    try {
      if (_taskId == null) {
        final result = await ApiDraw.createDrawTask(
          title: _title,
          rangeUserList: _inRangeUserList,
          reproducible: _reproducible,
          drawResult: _drawResult,
        );
        if (result is String) return result;
        if (result is int) _taskId = result;
        _dirty = false;
        return null;
      }
      if (!_dirty) return null;
      final result = await ApiDraw.updateDrawTask(
        taskId: _taskId!,
        title: _title,
        rangeUserList: _inRangeUserList,
        reproducible: _reproducible,
        drawResult: _drawResult,
      );
      if (result is String) return result;
      _dirty = false;
      return null;
    } finally {
      _syncing = false;
    }
  }

  /// 同步并给出提示, 由用户操作触发时使用
  Future<void> _syncWithFeedback() async {
    final error = await _syncToServer();
    if (!mounted) return;
    if (error != null) {
      showToast(msg: "保存失败, $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBackHandler(
      onWillPop: () async {
        await _syncWithFeedback();
        return true;
      },
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
        IconButton(
          onPressed: () async {
            final result = await showPromptDialog(
              context: context,
              title: "请输入更改任务名",
              label: "更改后的任务名",
              initValue: _title,
            );
            if (result is String) {
              _title = result;
              _dirty = true;
              setState(() {});
              await _syncWithFeedback();
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
            child: _drawResult.isEmpty
                ? Center(
                    child: Text(
                      "还没有抽取记录\n在下方设置人数后点击抽取",
                      textAlign: TextAlign.center,
                      style: textFieldHintStyle,
                    ),
                  )
                : ListView.builder(
                    itemCount: _drawResult.length,
                    itemBuilder: (BuildContext context, int i) {
                      final list = _drawResultReversed[i];
                      final avatarList = List.generate(list.length, (index) {
                        String id = list[index];
                        String username = _usernameOf(id);
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
                          _dirty = true;
                          _correctValue();
                          setState(() {});
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          _reproducible = !_reproducible;
                          _dirty = true;
                          _correctValue();
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
              _dirty = true;
              _correctValue();
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
              _dirty = true;
              _correctValue();
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
                if (_selectedIdList.isEmpty) {
                  showToast(msg: "还没有抽到任何人");
                  return;
                }
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

  /// 查询学号对应的昵称, 服务端返回的范围数据里没有昵称时回退到学号
  String _usernameOf(String id) {
    for (final user in _inRangeUserList) {
      if (user["id"] == id && user["username"] is String) {
        return user["username"];
      }
    }
    return UserCache.getUsername(id) ?? id;
  }

  Future<void> _performDraw() async {
    int drawNumber = int.tryParse(_drawNumberController.text) ?? 1;

    List<String> availableIds = _reproducible
        ? _inRangeUserIdList
        : _remainingIdList;

    if (drawNumber > availableIds.length) {
      drawNumber = availableIds.length;
    }

    if (drawNumber <= 0 || availableIds.isEmpty) {
      showToast(msg: '没有足够的用户可供抽取');
      return;
    }

    final random = Random();
    final shuffledIds = availableIds.toList()..shuffle(random);
    final drawnIds = shuffledIds.take(drawNumber).toList();
    _drawResult.add(drawnIds);
    _dirty = true;

    setState(() {});

    // 第一次抽取时才在服务端建立任务, 之后的抽取不断追加结果
    if (ApiService.userType == "guest") return;
    _message.value = _taskId == null ? "正在创建任务中" : "正在保存抽取结果中";
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async => _syncToServer()),
      initMessageList: [],
      messageList: ["正在保存中.", "正在保存中..", "正在保存中..."],
      successMessage: "保存成功",
      successMessageDuration: Duration(milliseconds: 300),
      failMessageDuration: Duration(milliseconds: 800),
    );
    if (mounted) Navigator.of(context).pop();
    if (!success && mounted) {
      showToast(msg: "抽取结果未能保存到服务器, 请检查网络后重试");
    }
  }
}

class TaskDrawPageArgs {
  /// 抽取范围来源, 从群组发起时使用
  final GroupStorageKey? groupStorageKey;

  /// 首页任务卡片点进来时已有的任务 ID
  final int? taskId;

  /// 首页任务卡片点进来时已有的任务数据
  final DrawTaskStorageData? data;
  const TaskDrawPageArgs({this.groupStorageKey, this.taskId, this.data});
}
