import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/bottom_sheet.dart';
import 'package:shine/components/line.dart';
import 'package:shine/database/database.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/event.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/storage/semester_storage.dart';
import 'package:shine/storage/subject_storage.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/course.dart';
import 'package:shine/utils/debouncer.dart';
import 'package:shine/utils/upload.dart';
import 'package:shine/views/message_view.dart';
import 'package:shine/views/schedule_view.dart';
import 'package:shine/views/task_view.dart';
import 'package:shine/views/user_view.dart';
import 'package:shine/worker/worker.dart';

const _userTypeStyleMap = {
  "guest": ("访客", Colors.grey, Color.fromRGBO(255, 255, 255, 0.5)),
  "user": ("用户", Colors.lightGreen, Color.fromRGBO(255, 255, 255, 0.8)),
  "admin": ("管理员", Colors.amber, Color.fromRGBO(255, 255, 255, 0.9)),
};

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TaskStorageData> get _taskList =>
      _remoteTaskList.toList()..addAll(_localTaskList);
  final List<TaskStorageData> _localTaskList = [];
  final List<TaskStorageData> _remoteTaskList = [];
  final List<TaskStorageData> _taskNoticeList = [];
  final List<UploadData> _myUploadsList = [];
  final List<MessageStorageData> _messageList = [];
  final List _userInfoList = [];
  final Debouncer _messageEventUpdateDebouncer = Debouncer();
  StreamSubscription<MessageEvent>? _subscription;
  int _ts = 0;
  String _username = "???";
  String _id = "??????????";
  int _currentIndex = 0;
  final ValueNotifier<String> _message = ValueNotifier("");
  final _bottomItemOptions = [
    (Icons.message_outlined, Icons.message, "消息"),
    (Icons.task_outlined, Icons.task, "任务"),
    (Icons.schedule_outlined, Icons.schedule_send, "日程"),
    (Icons.group_outlined, Icons.group, "成员"),
  ];
  int _getBadgeCountFromIndex(index) {
    switch (index) {
      case 0:
        return _messageList.where((m) => !m.readed).length;
    }
    return 0;
  }

  String? _semesterName;
  DateTime? _semesterStartedAt;
  final List<List<TimeOfDay>> _semesterPhaseList = [];
  final List<CourseData> _subjectInfo = [];
  final List<ScheduleData> _scheduleDataList = [];
  DateTime _showDate = DateTime.now();
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    HomePageRefreshNotifier._refreshTask = () {
      if (!mounted) return;
      _updateTaskData();
    };
    HomePageRefreshNotifier._refreshMessage = () {
      if (!mounted) return;
      _updateMessageData();
    };
    _subscription = EventBus.stream.listen((event) {
      _messageEventUpdateDebouncer.run(() {
        _updateMessageData();
      });
    });
    await DatabaseProvider.init();
    _loadMine();
    _loadSemesterData();
    _loadScheduleData();
    _updateAllData();
    _startWs();
    _prepareData();
    Worker.startSystemNotification();
  }

  Future<void> _prepareData() async {
    Worker.syncGlobalGroup();
  }

  Future<void> _startWs() async {
    Worker.startTaskWebSocket();
  }

  Future<void> _updateUserInfo() async {
    if (!mounted) return;
    await Worker.syncAllUser();
    final result = await ProfileStorage.getUserList();
    if (result != null) {
      _userInfoList.clear();
      _userInfoList.addAll(result);
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _loadMine() async {
    if (!mounted) return;
    _username = await ProfileStorage.getName();
    _id = await ProfileStorage.getId();
    _ts = await ProfileStorage.getAvatarTs();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _updateMine() async {
    await Worker.syncMyData();
    _loadMine();
  }

  Future<void> _updateTaskData() async {
    _localTaskList.clear();
    _localTaskList.addAll((await TaskStorage.getAllTask()).reversed.toList());
    setState(() {});
    if (ApiService.userType != "guest") {
      final remoteTask = await Worker.syncTask();
      if (remoteTask != null) {
        _remoteTaskList.clear();
        _remoteTaskList.addAll(remoteTask);
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _updateMessageData() async {
    _messageList.clear();
    _messageList.addAll(
      (await MessageStorage.getAllMessage()).reversed.toList(),
    );
    if (!mounted) return;
    setState(() {});
    final taskNoticeResult = await Worker.syncTaskNotice();
    if (taskNoticeResult is List<TaskStorageData>) {
      _taskNoticeList.clear();
      _taskNoticeList.addAll(taskNoticeResult);
      if (!mounted) return;
      setState(() {});
    }
    final taskUploadResult = await Worker.syncMyUploads();
    if (taskUploadResult is List<UploadData>) {
      _myUploadsList.clear();
      _myUploadsList.addAll(taskUploadResult);
    }
  }

  Future<void> _loadSemesterData() async {
    _semesterName = await SemesterStorage.getCurrentSemesterName();
    _semesterStartedAt = await SemesterStorage.getCurrentSemesterStartedAt();
    final r = await SemesterStorage.getCurrentSemesterPhaseList();
    if (r != null) {
      _semesterPhaseList.clear();
      _semesterPhaseList.addAll(r);
    }
  }

  Future<void> _updateSemesterData() async {
    if (!mounted) return;
    await Worker.syncSemester();
    await _loadSemesterData();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadScheduleData() async {
    _subjectInfo.clear();
    _subjectInfo.addAll(await SubjectStorage.getCurrentSubjectInfo());
    _scheduleDataList.clear();
    _scheduleDataList.addAll(await SubjectStorage.getCurrentScheduleInfo());
  }

  Future<void> _updateScheduleData() async {
    if (!mounted) return;
    final subjectInfoResult = await Worker.syncSubjects();
    if (subjectInfoResult is List<CourseData>) {
      _subjectInfo.clear();
      _subjectInfo.addAll(subjectInfoResult);
    }
    final scheduleResult = await Worker.syncSchedule();
    if (scheduleResult is List<ScheduleData>) {
      _scheduleDataList.clear();
      _scheduleDataList.addAll(scheduleResult);
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _updateAllData() async {
    _updateTaskData();
    _updateMessageData();
    await _updateSemesterData();
    await _updateScheduleData();
    await _updateMine();
    await _updateUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            MessageView(
              taskNoticeList: _taskNoticeList,
              messageList: _messageList,
              uploadDataList: _myUploadsList,
              onRefresh: () async {
                await _updateMessageData();
              },
            ),
            TaskView(
              taskList: _taskList,
              onRefresh: () async {
                await _updateTaskData();
              },
            ),
            ScheduleView(
              semesterPhaseList: _semesterPhaseList,
              semesterName: _semesterName,
              semesterStartedAt: _semesterStartedAt,
              subjectInfoList: _subjectInfo,
              scheduleDataList: _scheduleDataList,
              onRefresh: () async {
                await _updateSemesterData();
                await _updateScheduleData();
              },
              onChangeShowDate: (DateTime d) {
                _showDate = d;
                setState(() {});
              },
              showDate: _showDate,
            ),
            UserView(
              userInfoList: _userInfoList,
              message: _message,
              onRefresh: () async {
                await _updateUserInfo();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottombar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  if (context.mounted) {
                    await globalNavigatorKey.currentState?.pushNamed(
                      '/profile',
                    );
                    _loadMine();
                  }
                },
                child: NetworkAvatar(id: _id, ts: _ts, radius: 25),
              ),
              SizedBox(width: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _username,
                    style: TextStyle(
                      letterSpacing: 1.0,
                      fontFamily: "SmileySans",
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Row(
                    children: [
                      _buildAccessSignal(),
                      const SizedBox(width: 3),
                      Text(
                        _id,
                        style: TextStyle(
                          fontFamily: "SmileySans",
                          color: Colors.grey,
                          fontWeight: FontWeight.w300,
                          fontSize: 12,
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
      bottom: bottomLine,
      actions: [
        IndexedStack(
          index: _currentIndex,
          children: [
            SizedBox(),
            IconButton(
              onPressed: () {
                showTaskGridBottomSheet(context);
              },
              icon: Icon(Icons.add, size: 32),
            ),
            SizedBox(),
            SizedBox(),
          ],
        ),
      ],
    );
  }

  Widget _buildAccessSignal() {
    late (String, Color, Color) r;
    if (_userTypeStyleMap.containsKey(ApiService.userType)) {
      r = _userTypeStyleMap[ApiService.userType]!;
    } else {
      r = _userTypeStyleMap["guest"]!;
    }
    return GestureDetector(
      child: Container(
        alignment: Alignment.center,
        height: 20,
        decoration: BoxDecoration(
          color: r.$2,
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        child: Text(
          r.$1,
          style: TextStyle(fontSize: 10, color: r.$3, fontFamily: 'SmileySans'),
        ),
      ),
    );
  }

  Widget _buildBottombar() {
    return Container(
      decoration: BoxDecoration(
        color: bgColorLight80,
        border: Border(
          top: BorderSide(
            color: const Color.fromRGBO(158, 158, 158, 0.8),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedLabelStyle: const TextStyle(fontFamily: "SmileySans"),
        unselectedLabelStyle: const TextStyle(fontFamily: "SmileySans"),
        items: List.generate(_bottomItemOptions.length, (index) {
          final record = _bottomItemOptions[index];
          final count = _getBadgeCountFromIndex(index);
          return BottomNavigationBarItem(
            icon: Badge.count(
              backgroundColor: mainColorRed,
              textColor: bgColorLight,
              isLabelVisible: count != 0,
              count: count,
              child: Icon(record.$1),
            ),
            activeIcon: Badge.count(
              backgroundColor: mainColorRed,
              textColor: bgColorLight,
              isLabelVisible: count != 0,
              count: count,
              child: Icon(record.$2),
            ),
            label: record.$3,
          );
        }),
        onTap: (value) {
          _currentIndex = value;
          setState(() {});
        },
      ),
    );
  }

  @override
  void dispose() {
    HomePageRefreshNotifier.clear();
    _subscription?.cancel();
    super.dispose();
  }
}

class HomePageRefreshNotifier {
  static VoidCallback? _refreshTask;
  static VoidCallback? _refreshMessage;

  static void refreshTask() {
    _refreshTask ??= () {};
    _refreshTask!();
  }

  static void refreshMessage() {
    _refreshMessage ??= () {};
    _refreshMessage!();
  }

  static void clear() {
    _refreshTask = null;
    _refreshMessage = null;
  }
}
