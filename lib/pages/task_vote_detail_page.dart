import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shine/components/custom_back_handler.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/task.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/components/user_info_bar.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/services/api_vote.dart';
import 'package:shine/services/event.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/async_utils.dart';
import 'package:shine/utils/image_utils.dart';
import 'package:shine/utils/message_utils.dart';
import 'package:shine/utils/share_utils.dart';
import 'package:shine/utils/time_utils.dart';

class TaskVoteDetailPage extends StatefulWidget {
  const TaskVoteDetailPage({super.key});

  @override
  State<TaskVoteDetailPage> createState() => _TaskVoteDetailPageState();
}

class _TaskVoteDetailPageState extends State<TaskVoteDetailPage> {
  final GlobalKey _key = GlobalKey();
  final ValueNotifier<String> _message = ValueNotifier("正在提交中");
  Map<String, dynamic>? _vote;
  String? _error;
  bool _loading = true;
  /// 用户改动过的选择, 服务端刷新时不覆盖
  final Set<int> _selectedOptionIds = {};
  StreamSubscription<VoteEvent>? _voteSubscription;

  /// 当前查看的投票任务 ID
  int _resolvedTaskId = 0;

  @override
  void initState() {
    super.initState();
    _voteSubscription = VoteEventBus.stream.listen((event) {
      if (event.taskId != _resolvedTaskId) return;
      _load(silent: true);
    });
    AsyncUtils.postFrame(() async {
      await _load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is TaskVoteDetailPageArgs) {
      _resolvedTaskId = args.taskId;
    } else if (args is VoteTaskStorageData) {
      _resolvedTaskId = args.id;
    }
  }

  @override
  void dispose() {
    _voteSubscription?.cancel();
    _message.dispose();
    super.dispose();
  }

  bool get _isCreator => _vote?["isCreator"] == true;
  bool get _isVoter => _vote?["isVoter"] == true;
  bool get _ended => _vote?["ended"] == true;
  bool get _multiple => _vote?["multiple"] == true;
  int get _maxChoices => _vote?["maxChoices"] is int
      ? _vote!["maxChoices"] as int
      : 1;
  bool get _resultVisible => _vote?["resultVisible"] == true;
  String get _title => _vote?["title"] is String
      ? _vote!["title"] as String
      : "投票详情";
  List<Map<String, dynamic>> get _optionList {
    final options = _vote?["options"];
    if (options is! List) return [];
    return options.whereType<Map<String, dynamic>>().toList();
  }

  List<Map<String, dynamic>> get _voterList {
    final voters = _vote?["voterList"];
    if (voters is! List) return [];
    return voters.whereType<Map<String, dynamic>>().toList();
  }

  List<Map<String, dynamic>> get _notVotedList =>
      _voterList.where((voter) => voter["voted"] != true).toList();

  int get _participantCount => _vote?["participantCount"] is int
      ? _vote!["participantCount"] as int
      : 0;
  int get _votedCount =>
      _vote?["votedCount"] is int ? _vote!["votedCount"] as int : 0;

  Future<void> _load({bool silent = false}) async {
    final taskId = _resolvedTaskId;
    if (taskId <= 0) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "缺少投票任务信息";
      });
      return;
    }
    if (!silent && mounted) setState(() => _loading = true);
    final result = await ApiVote.getVoteTask(taskId);
    if (!mounted) return;
    if (result is! Map) {
      // 静默刷新失败时保留旧数据, 不打断正在投票的用户
      if (silent) return;
      setState(() {
        _loading = false;
        _error = result is String ? result : "获取投票信息失败";
      });
      return;
    }
    final myOptionIds = result["myOptionIds"];
    final Set<int> serverSelection = {};
    if (myOptionIds is List) {
      serverSelection.addAll(myOptionIds.whereType<int>());
    }
    setState(() {
      _vote = Map<String, dynamic>.from(result);
      _loading = false;
      _error = null;
      // 已经在服务端投过票时以服务端记录为准
      if (serverSelection.isNotEmpty) {
        _selectedOptionIds
          ..clear()
          ..addAll(serverSelection);
      }
    });
  }

  void _toggleOption(int optionId) {
    if (_ended || !_isVoter) return;
    if (!_multiple) {
      _selectedOptionIds
        ..clear()
        ..add(optionId);
      setState(() {});
      return;
    }
    if (_selectedOptionIds.contains(optionId)) {
      _selectedOptionIds.remove(optionId);
      setState(() {});
      return;
    }
    if (_selectedOptionIds.length >= _maxChoices) {
      showToast(msg: "最多只能选择$_maxChoices项");
      return;
    }
    _selectedOptionIds.add(optionId);
    setState(() {});
  }

  Future<void> _submit() async {
    final optionIds = _selectedOptionIds.toList();
    if (optionIds.isEmpty) {
      showToast(msg: "请先选择选项");
      return;
    }
    _message.value = "正在提交投票中";
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        final result = await ApiVote.submitVote(
          taskId: _resolvedTaskId,
          optionIds: optionIds,
        );
        if (result is String) return result;
        return null;
      }),
      initMessageList: [],
      messageList: ["正在提交中.", "正在提交中..", "正在提交中..."],
      successMessage: "投票成功",
      successMessageDuration: Duration(milliseconds: 300),
      failMessageDuration: Duration(milliseconds: 800),
    );
    if (mounted) Navigator.of(context).pop();
    if (!success) return;
    showToast(msg: "投票已提交");
    await _load(silent: true);
    HomePageRefreshNotifier.refreshTask();
  }

  /// 发起人提前结束投票
  Future<void> _endVote() async {
    final confirm = await showConfirmDialog(
      context: context,
      title: "结束投票",
      content: "结束后将不能再提交投票, 确定结束“$_title”吗？",
    );
    if (!confirm) return;
    _message.value = "正在结束投票中";
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        // 结束时间取当前时刻, 服务端只要求晚于开始时间
        final result = await ApiVote.updateVoteTask(
          taskId: _resolvedTaskId,
          taskData: {
            "endedAt": DateTime.now().millisecondsSinceEpoch,
          },
        );
        if (result is String) return result;
        return null;
      }),
      initMessageList: [],
      messageList: ["正在结束中.", "正在结束中..", "正在结束中..."],
      successMessage: "已结束",
      successMessageDuration: Duration(milliseconds: 300),
      failMessageDuration: Duration(milliseconds: 800),
    );
    if (mounted) Navigator.of(context).pop();
    if (!success) return;
    showToast(msg: "投票已结束");
    await _load(silent: true);
    HomePageRefreshNotifier.refreshTask();
  }

  Future<void> _remindNotVoted() async {    final idList = _notVotedList
        .map((voter) => voter["id"])
        .whereType<String>()
        .toList();
    if (idList.isEmpty) {
      showToast(msg: "所有参与者都已投票");
      return;
    }
    try {
      await WsTask.sendRemind(
        msg: "投票“$_title”还没有完成, 请尽快投票",
        targetList: idList,
        level: 5,
      );
      showToast(msg: "已提醒${idList.length}名同学");
    } catch (err) {
      showToast(msg: "发送失败, ${err.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBackHandler(
      child: RepaintBoundary(
        key: _key,
        child: Scaffold(
          appBar: _buildAppBar(),
          body: SafeArea(child: _buildBody()),
          bottomNavigationBar: _loading || _vote == null
              ? null
              : _buildBottomBar(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_vote == null ? "投票详情" : _title, style: titleTextStyle),
      centerTitle: true,
      bottom: bottomLine,
      actions: [
        IconButton(
          onPressed: () => _load(),
          icon: Icon(Icons.refresh, size: 28),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: bodyPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: labelStyle, textAlign: TextAlign.center),
              SizedBox(height: 12),
              TextButton(
                style: dialogButtonStyle,
                onPressed: () => _load(),
                child: Text("重试"),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: bodyPadding,
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 10),
        ..._buildOptionList(),
        if (_isCreator) ...[const SizedBox(height: 10), _buildVoterProgress()],
      ],
    );
  }

  Widget _buildHeaderCard() {
    final creatorName = _vote?["creatorName"] is String
        ? _vote!["creatorName"] as String
        : "未知用户";
    final endedAt = _vote?["endedAt"] is int
        ? DateTime.fromMillisecondsSinceEpoch(_vote!["endedAt"] as int)
        : DateTime.now();
    final tags = <String>[
      if (_multiple) "多选(最多$_maxChoices项)" else "单选",
      if (_vote?["anonymous"] == true) "匿名",
      if (_ended) "已结束" else "进行中",
    ];
    return Container(
      padding: EdgeInsets.all(16),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  _title,
                  style: const TextStyle(
                    fontFamily: "SmileySans",
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final tag in tags)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: purpleLinearGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontFamily: "SmileySans",
                      fontSize: 13,
                      color: bgColorLight,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text("发起人：$creatorName", style: labelStyle),
          Text(
            "截止：${getLocalTimeString(endedAt)}(${getDayDifferenceString(endedAt)})",
            style: labelStyle,
          ),
          Text("参与：$_votedCount/$_participantCount 人已投票", style: labelStyle),
          if (_isVoter && _selectedOptionIds.isNotEmpty && !_ended)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text("你已投票, 可以重新选择后再次提交", style: textFieldHintStyle),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildOptionList() {
    final options = _optionList;
    if (options.isEmpty) {
      return [Text("该投票没有选项", style: labelStyle)];
    }
    int maxCount = 1;
    for (final option in options) {
      final count = option["count"];
      if (count is int && count > maxCount) maxCount = count;
    }
    return options.map((option) {
      final optionId = option["optionId"];
      final content = option["content"] is String
          ? option["content"] as String
          : "";
      final count = option["count"];
      final selected = optionId is int && _selectedOptionIds.contains(optionId);
      final ratio = count is int && _resultVisible
          ? (maxCount == 0 ? 0.0 : count / maxCount)
          : 0.0;
      return GestureDetector(
        onTap: optionId is int ? () => _toggleOption(optionId) : null,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected ? mainColorPurple50 : bgColorLight60,
            border: Border.all(
              color: selected ? mainColorPurple : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_isVoter && !_ended)
                    Icon(
                      _multiple
                          ? (selected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank)
                          : (selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked),
                      size: 22,
                      color: selected ? mainColorPurple : Colors.grey,
                    ),
                  if (_isVoter && !_ended) const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontFamily: "SmileySans",
                        fontSize: 17,
                      ),
                    ),
                  ),
                  if (count is int)
                    Text(
                      "$count票",
                      style: const TextStyle(
                        fontFamily: "SmileySans",
                        fontSize: 16,
                        color: mainColorRed,
                      ),
                    ),
                ],
              ),
              if (count is int) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio.toDouble(),
                    minHeight: 6,
                    backgroundColor: bgColorLight,
                    valueColor: AlwaysStoppedAnimation<Color>(mainColorRed50),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildVoterProgress() {
    final voters = _voterList;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: bgColorLight60,
      ),
      child: ExpansionTile(
        title: Text(
          "参与进度($_votedCount/$_participantCount)",
          style: expansionListTitleStyle,
        ),
        children: [
          if (voters.isEmpty)
            Padding(
              padding: EdgeInsets.all(10),
              child: Text("暂时没有参与人信息", style: textFieldHintStyle),
            ),
          for (final voter in voters)
            UserInfoBar(
              id: voter["id"] is String ? voter["id"] as String : "",
              username: voter["username"] is String
                  ? voter["username"] as String
                  : "未知用户",
              suffixIcon: Icon(
                voter["voted"] == true
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 18,
                color: voter["voted"] == true ? mainColorGreenBlue : Colors.grey,
              ),
              idStyle: TextStyle(
                fontFamily: "SmileySans",
                fontSize: 15,
                color: Colors.grey,
              ),
              usernameStyle: TextStyle(
                fontFamily: "SmileySans",
                fontSize: 15,
                color: voter["voted"] == true ? Colors.black87 : Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final items = <Widget>[];
    if (_isVoter && !_ended) {
      items.add(
        buildBottomItem(
          onTap: _submit,
          icon: Icons.how_to_vote,
          title: _selectedOptionIds.isEmpty ? '提交投票' : '提交投票(${_selectedOptionIds.length})',
        ),
      );
    }
    if (_isCreator && !_ended) {
      items.add(
        buildBottomItem(
          onTap: _remindNotVoted,
          icon: Icons.notifications_outlined,
          title: '提醒未投票',
        ),
      );
      items.add(
        buildBottomItem(
          onTap: _endVote,
          icon: Icons.flag_outlined,
          title: '结束投票',
        ),
      );
    }
    items.add(
      buildBottomItem(
        onTap: () async {
          final image = await captureWidgetToPng(globalKey: _key);
          if (image == null) {
            showToast(msg: "获取屏幕信息失败");
            return;
          }
          await shareImage(
            image: image,
            name: "vote_result.png",
            title: _title,
          );
        },
        icon: Icons.share_outlined,
        title: '分享到...',
      ),
    );
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
          children: items,
        ),
      ),
    );
  }
}

class TaskVoteDetailPageArgs {
  final int taskId;
  final VoteTaskStorageData? data;
  const TaskVoteDetailPageArgs({required this.taskId, this.data});
}
