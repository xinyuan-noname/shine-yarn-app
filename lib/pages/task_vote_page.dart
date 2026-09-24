import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/cache/user_cache.dart';
import 'package:shine/components/custom_back_handler.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/dual_column_list.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/task.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/components/user_info_bar.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_vote.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/async_utils.dart';
import 'package:shine/utils/image_utils.dart';
import 'package:shine/utils/message_utils.dart';
import 'package:shine/utils/share_utils.dart';
import 'package:shine/utils/time_utils.dart';
import 'package:shine/worker/worker.dart';

/// 截止时间快捷选项
const List<(String, Duration)> _deadlinePresetList = [
  ("30分钟", Duration(minutes: 30)),
  ("1小时", Duration(hours: 1)),
  ("3小时", Duration(hours: 3)),
  ("12小时", Duration(hours: 12)),
  ("1天", Duration(days: 1)),
  ("3天", Duration(days: 3)),
];

/// 选项数量上限, 与服务端保持一致
const int _optionMaxLength = 30;

class TaskVotePage extends StatefulWidget {
  const TaskVotePage({super.key});

  @override
  State<TaskVotePage> createState() => _TaskVotePageState();
}

class _TaskVotePageState extends State<TaskVotePage> {
  final String _title = "发起投票";
  final GlobalKey _key = GlobalKey();
  final ValueNotifier<String> _message = ValueNotifier("正在发起投票中");

  final TextEditingController _votingTitleController = TextEditingController();
  final List<TextEditingController> _optionControllerList = [];

  bool _multiple = false;
  bool _anonymous = false;
  int _maxChoices = 2;
  DateTime _endedAt = DateTime.now().add(const Duration(hours: 1));
  int? _deadlinePresetIndex = 1;

  /// 参与投票的同学
  final List<Map<String, dynamic>> _participantList = [];

  /// 还未完成的投票数量
  int _pendingVoteCount = 0;

  List<Map<String, dynamic>> get _allUserList {
    final Map<String, Map<String, dynamic>> merged = {};
    for (final user in UserCache.getUserList()) {
      final id = user["id"];
      if (id is String) merged[id] = user;
    }
    for (final user in _participantList) {
      final id = user["id"];
      if (id is String) merged[id] = user;
    }
    return merged.values.toList();
  }

  List<Map<String, dynamic>> get _outRangeUserList => _allUserList
      .where(
        (user) => !_participantList.any((userIn) => user["id"] == userIn["id"]),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _optionControllerList.addAll([
      TextEditingController(),
      TextEditingController(),
    ]);
    _init();
  }

  @override
  void dispose() {
    _votingTitleController.dispose();
    for (final controller in _optionControllerList) {
      controller.dispose();
    }
    _message.dispose();
    super.dispose();
  }

  Future _init() async {
    await AsyncUtils.postFrame(() async {
      // 默认把全班同学作为参与人, 老师可以再手动调整
      final list = await Worker.getUserListByGroup(GroupStorageKey.entire);
      if (!mounted) return;
      if (list.isNotEmpty) {
        _participantList.clear();
        _participantList.addAll(list);
        setState(() {});
      }
    });
    _syncPendingVoteCount();
  }

  /// 查询还有多少投票没有完成, 在入口上给出提醒
  Future<void> _syncPendingVoteCount() async {
    final result = await ApiVote.getMyVoteList();
    if (!mounted) return;
    if (result is! Map) return;
    final participated = result["participated"];
    if (participated is! List) return;
    var count = 0;
    for (final vote in participated.whereType<Map<String, dynamic>>()) {
      if (vote["ended"] != true && vote["voted"] != true) count++;
    }
    setState(() {
      _pendingVoteCount = count;
    });
  }

  /// 用指定群组重置参与人名单
  Future<void> _resetParticipantByGroup() async {
    final key = await showGroupStorageKeySelectionDialog(
      context: context,
      title: "选择参与投票的群组",
    );
    if (key is! GroupStorageKey) return;
    final list = await Worker.getUserListByGroup(key);
    if (!mounted) return;
    _participantList.clear();
    _participantList.addAll(list);
    setState(() {});
    showToast(msg: "已选择${groupStorageKeyLabelMap[key] ?? ""}(${list.length}人)");
  }

  void _addOption() {
    if (_optionControllerList.length >= _optionMaxLength) {
      showToast(msg: "最多只能添加$_optionMaxLength个选项");
      return;
    }
    _optionControllerList.add(TextEditingController());
    setState(() {});
  }

  void _removeOption(int index) {
    if (index <= 0 || _optionControllerList.length <= 2) {
      showToast(msg: "至少需要保留两个选项");
      return;
    }
    _optionControllerList.removeAt(index).dispose();
    if (_maxChoices > _optionControllerList.length) {
      _maxChoices = _optionControllerList.length;
    }
    setState(() {});
  }

  List<String> get _optionContentList => _optionControllerList
      .map((controller) => controller.text.trim())
      .where((content) => content.isNotEmpty)
      .toList();

  Future<void> _pickCustomDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _endedAt.isAfter(now) ? _endedAt : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date is! DateTime) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endedAt),
    );
    if (time is! TimeOfDay) return;
    final result = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (result.isBefore(DateTime.now())) {
      showToast(msg: "截止时间必须晚于当前时间");
      return;
    }
    _endedAt = result;
    _deadlinePresetIndex = null;
    setState(() {});
  }

  Future<void> _createVote() async {
    final title = _votingTitleController.text.trim();
    if (title.isEmpty) {
      showToast(msg: "请输入投票标题");
      return;
    }
    final options = _optionContentList;
    if (options.length < 2) {
      showToast(msg: "至少需要填写两个选项");
      return;
    }
    if (options.toSet().length != options.length) {
      showToast(msg: "选项内容不能重复");
      return;
    }
    final voters = GroupStorage.getIdList(_participantList);
    if (voters.isEmpty) {
      showToast(msg: "请选择参与投票的同学");
      return;
    }
    if (_endedAt.isBefore(DateTime.now())) {
      showToast(msg: "截止时间必须晚于当前时间");
      return;
    }

    _message.value = "正在发起投票中";
    showMessageDialog(context, _message);
    String? pushTip;
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        final result = await ApiVote.createVoteTask(
          title: title,
          options: options,
          voters: voters,
          multiple: _multiple,
          maxChoices: _multiple ? _maxChoices : null,
          anonymous: _anonymous,
          endedAt: _endedAt,
        );
        if (result is String) return result;
        if (result is Map) {
          final online = result["onlineCount"] ?? 0;
          final offline = result["offlineCount"] ?? 0;
          final total =
              (online is int ? online : 0) + (offline is int ? offline : 0);
          pushTip = "已通知$total名同学, 其中$offline人离线";
        }
        return null;
      }),
      initMessageList: [],
      messageList: ["正在发起中.", "正在发起中..", "正在发起中..."],
      successMessage: "发起成功",
      successMessageDuration: Duration(milliseconds: 300),
      failMessageDuration: Duration(milliseconds: 800),
    );
    if (mounted) Navigator.of(context).pop();
    if (!success) return;
    showToast(msg: pushTip ?? "投票已发起");
    _resetForm();
    HomePageRefreshNotifier.refreshTask();
  }

  void _resetForm() {
    if (!mounted) return;
    setState(() {
      _votingTitleController.clear();
      for (final controller in _optionControllerList) {
        controller.dispose();
      }
      _optionControllerList
        ..clear()
        ..addAll([TextEditingController(), TextEditingController()]);
      _multiple = false;
      _anonymous = false;
      _maxChoices = 2;
      _endedAt = DateTime.now().add(const Duration(hours: 1));
      _deadlinePresetIndex = 1;
    });
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
                      tabs: [Text("发起投票"), Text("参与人员")],
                      labelStyle: tabLabelStyle,
                      padding: EdgeInsets.only(top: 2),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildVotingWidget(),
                          _buildParticipantWidget(),
                        ],
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
          tooltip: "参与中的投票",
          onPressed: () async {
            await globalNavigatorKey.currentState?.pushNamed('/task/vote/list');
            if (!mounted) return;
            _syncPendingVoteCount();
            HomePageRefreshNotifier.refreshTask();
          },
          icon: _pendingVoteCount > 0
              ? Badge.count(
                  count: _pendingVoteCount,
                  child: Icon(Icons.list_alt, size: 28),
                )
              : Icon(Icons.list_alt, size: 28),
        ),
      ],
    );
  }

  Widget _buildVotingWidget() {
    return Container(
      padding: bodyPadding,
      child: Column(
        children: [
          Expanded(
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
                      hintText: "请输入本次投票的标题",
                      hintStyle: textFieldHintStyle,
                    ),
                    controller: _votingTitleController,
                    textAlign: TextAlign.start,
                    style: textFieldStyle,
                    maxLength: 100,
                    buildCounter:
                        (
                          _, {
                          required bool isFocused,
                          int? currentLength,
                          int? maxLength,
                        }) => null,
                  ),
                  const SizedBox(height: 5),
                  bottomLine,
                  const SizedBox(height: 5),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _optionControllerList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _optionControllerList.length) {
                          return GestureDetector(
                            onTap: _addOption,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 2),
                              padding: EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add_circle_outline_outlined,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 8),
                                  Text("添加选项", style: textFieldHintStyle),
                                ],
                              ),
                            ),
                          );
                        }
                        return _buildOptionRow(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingPanel(),
        ],
      ),
    );
  }

  Widget _buildOptionRow(int index) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 1, color: bgColorLight)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _removeOption(index),
            child: Icon(
              index > 0 ? Icons.remove_circle_outline : Icons.panorama_fish_eye,
              color: index > 0
                  ? const Color.fromRGBO(158, 158, 158, 1)
                  : const Color.fromRGBO(158, 158, 158, 0.5),
            ),
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 2),
                hintText: "选项${index + 1}",
                hintStyle: textFieldHintStyle,
              ),
              controller: _optionControllerList[index],
              textAlign: TextAlign.start,
              style: textFieldStyle,
              maxLength: 100,
              buildCounter:
                  (
                    _, {
                    required bool isFocused,
                    int? currentLength,
                    int? maxLength,
                  }) => null,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingPanel() {
    final optionCount = _optionContentList.length;
    final maxLimit = optionCount < 2 ? 2 : optionCount;
    if (_maxChoices > maxLimit) _maxChoices = maxLimit;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: purpleLinearGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCheckItem(
                label: "多选",
                value: _multiple,
                onChanged: (value) {
                  _multiple = value;
                  if (_multiple && _maxChoices > maxLimit) {
                    _maxChoices = maxLimit;
                  }
                  setState(() {});
                },
              ),
              if (_multiple) ...[
                const SizedBox(width: 12),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  iconSize: 20,
                  onPressed: () {
                    if (_maxChoices > 1) {
                      _maxChoices--;
                      setState(() {});
                    }
                  },
                  icon: Icon(Icons.remove_circle_outline),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text("最多$_maxChoices项", style: purpleButtonStyle),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  iconSize: 20,
                  onPressed: () {
                    if (_maxChoices < maxLimit) {
                      _maxChoices++;
                      setState(() {});
                    }
                  },
                  icon: Icon(Icons.add_circle_outline),
                ),
              ],
              const Spacer(),
              _buildCheckItem(
                label: "匿名",
                value: _anonymous,
                onChanged: (value) {
                  _anonymous = value;
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "截止: ${getLocalTimeString(_endedAt)}(${getDayDifferenceString(_endedAt)})",
                  style: labelStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (int i = 0; i < _deadlinePresetList.length; i++)
                _buildChip(
                  label: _deadlinePresetList[i].$1,
                  selected: _deadlinePresetIndex == i,
                  onTap: () {
                    _deadlinePresetIndex = i;
                    _endedAt = DateTime.now().add(_deadlinePresetList[i].$2);
                    setState(() {});
                  },
                ),
              _buildChip(
                label: "自定义",
                selected: _deadlinePresetIndex == null,
                onTap: _pickCustomDeadline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            visualDensity: VisualDensity.compact,
            onChanged: (result) => onChanged(result ?? false),
          ),
          Text(label, style: labelStyle),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? mainColorPurple : bgColorLight60,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: mainColorPurple, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: "SmileySans", fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildParticipantWidget() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "共${_participantList.length}人参与投票",
                  style: labelStyle,
                ),
              ),
              TextButton.icon(
                style: dialogButtonStyle,
                onPressed: _resetParticipantByGroup,
                icon: Icon(Icons.groups, size: 18),
                label: Text("按群组选择"),
              ),
            ],
          ),
        ),
        Expanded(
          child: DualColumnList(
            leftTitle: "参与投票的同学",
            rightTitle: "不参与的同学",
            leftItems: _participantList,
            rightItems: _outRangeUserList,
            leftItemBuilder: (context, item, index) {
              final id = item["id"];
              final username = item["username"];
              if (id is String && username is String) {
                return UserInfoBar(
                  id: id,
                  username: username,
                  onTap: () {
                    _participantList.remove(item);
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
                    _participantList.add(item);
                    setState(() {});
                  },
                );
              }
              return null;
            },
          ),
        ),
      ],
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
                if (ApiService.userType == "guest") {
                  showToast(msg: "游客(无密码登录用户)暂不支持发起投票");
                  return;
                }
                await _createVote();
              },
              icon: Icons.how_to_vote_outlined,
              title: '发起投票',
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
                  name: "vote_task.png",
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
