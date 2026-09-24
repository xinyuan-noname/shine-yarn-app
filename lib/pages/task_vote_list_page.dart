import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shine/components/custom_back_handler.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/pages/task_vote_detail_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api_vote.dart';
import 'package:shine/services/event.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/async_utils.dart';
import 'package:shine/utils/time_utils.dart';

class TaskVoteListPage extends StatefulWidget {
  const TaskVoteListPage({super.key});

  @override
  State<TaskVoteListPage> createState() => _TaskVoteListPageState();
}

class _TaskVoteListPageState extends State<TaskVoteListPage> {
  final List<Map<String, dynamic>> _participatedList = [];
  final List<Map<String, dynamic>> _createdList = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<VoteEvent>? _voteSubscription;

  @override
  void initState() {
    super.initState();
    _voteSubscription = VoteEventBus.stream.listen((_) {
      _load(silent: true);
    });
    AsyncUtils.postFrame(() async {
      await _load();
    });
  }

  @override
  void dispose() {
    _voteSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    final result = await ApiVote.getMyVoteList();
    if (!mounted) return;
    if (result is! Map) {
      if (silent) return;
      setState(() {
        _loading = false;
        _error = result is String ? result : "获取投票列表失败";
      });
      return;
    }
    final participated = result["participated"];
    final created = result["created"];
    setState(() {
      _participatedList.clear();
      if (participated is List) {
        _participatedList.addAll(
          participated.whereType<Map<String, dynamic>>(),
        );
      }
      _createdList.clear();
      if (created is List) {
        _createdList.addAll(created.whereType<Map<String, dynamic>>());
      }
      _loading = false;
      _error = null;
    });
  }

  Future<void> _openVote(Map<String, dynamic> vote) async {
    final taskId = vote["taskId"];
    if (taskId is! int) return;
    await globalNavigatorKey.currentState?.pushNamed(
      '/task/vote/detail',
      arguments: TaskVoteDetailPageArgs(taskId: taskId),
    );
    await _load(silent: true);
    HomePageRefreshNotifier.refreshTask();
  }

  @override
  Widget build(BuildContext context) {
    return CustomBackHandler(
      child: Scaffold(
        appBar: AppBar(
          title: Text("我的投票", style: titleTextStyle),
          centerTitle: true,
          bottom: bottomLine,
          actions: [
            IconButton(
              onPressed: () => _load(),
              icon: Icon(Icons.refresh, size: 28),
            ),
          ],
        ),
        body: SafeArea(child: _buildBody()),
      ),
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
    if (_participatedList.isEmpty && _createdList.isEmpty) {
      return Center(
        child: Text("暂时还没有与你相关的投票", style: textFieldHintStyle),
      );
    }
    return ListView(
      padding: bodyPadding,
      children: [
        if (_participatedList.isNotEmpty) ...[
          _buildSectionTitle("我参与的投票(${_participatedList.length})"),
          for (final vote in _participatedList) _buildVoteCard(vote),
          const SizedBox(height: 12),
        ],
        if (_createdList.isNotEmpty) ...[
          _buildSectionTitle("我发起的投票(${_createdList.length})"),
          for (final vote in _createdList) _buildVoteCard(vote),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Text(title, style: listTitleStyle),
    );
  }

  Widget _buildVoteCard(Map<String, dynamic> vote) {
    final title = vote["title"] is String ? vote["title"] as String : "未命名投票";
    final creatorName = vote["creatorName"] is String
        ? vote["creatorName"] as String
        : "未知用户";
    final ended = vote["ended"] == true;
    final voted = vote["voted"] == true;
    final isCreator = vote["isCreator"] == true;
    final votedCount = vote["votedCount"] is int ? vote["votedCount"] as int : 0;
    final participantCount = vote["participantCount"] is int
        ? vote["participantCount"] as int
        : 0;
    final endedAt = vote["endedAt"] is int
        ? DateTime.fromMillisecondsSinceEpoch(vote["endedAt"] as int)
        : DateTime.now();

    String statusText;
    Color statusColor;
    if (ended) {
      statusText = "已结束";
      statusColor = Colors.grey;
    } else if (isCreator) {
      statusText = "进行中";
      statusColor = mainColorPurple;
    } else if (voted) {
      statusText = "已投票";
      statusColor = mainColorGreenBlue;
    } else {
      statusText = "待投票";
      statusColor = mainColorRed;
    }

    return GestureDetector(
      onTap: () => _openVote(vote),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: whiteLinearGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: "SmileySans",
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontFamily: "SmileySans",
                      fontSize: 13,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("发起人：$creatorName", style: labelStyle),
            Text(
              "参与：$votedCount/$participantCount 人已投票",
              style: labelStyle,
            ),
            Text(
              "截止：${getLocalTimeString(endedAt)}(${getDayDifferenceString(endedAt)})",
              style: labelStyle,
            ),
          ],
        ),
      ),
    );
  }
}
