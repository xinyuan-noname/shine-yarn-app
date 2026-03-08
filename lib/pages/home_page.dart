import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/bottom_sheet.dart';
import 'package:shine/components/line.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/event.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/storage/token_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/views/message_view.dart';
import 'package:shine/views/task_view.dart';
import 'package:shine/views/user_view.dart';
import 'package:shine/worker/worker.dart';

const selectedTextStyle = TextStyle(fontFamily: "SmileySans");
const unselectedTextStyle = TextStyle(fontFamily: "SmileySans");
const userTypeStyleMap = {
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
  final List<TaskStorageData> _taskList = [];
  final List<MessageStorageData> _messageList = [];
  final List _userInfoList = [];
  // ignore: unused_field
  StreamSubscription<MessageEvent>? _subscription;
  int _ts = 0;
  String _username = "???";
  String _id = "??????????";
  int _currentIndex = 0;
  String _userType = "guest";
  final ValueNotifier<String> _message = ValueNotifier("");
  final _bottomItemOptions = [
    (Icons.message_outlined, Icons.message, "消息"),
    (Icons.task_outlined, Icons.task, "任务"),
    (Icons.group_outlined, Icons.group, "成员"),
  ];

  @override
  void initState() {
    super.initState();
    _loadMine();
    _updateAllData();
    _prepareData();
    _startWs();
    HomePageRefreshNotifier._refreshTask = () {
      if (!mounted) return;
      _updateTaskData();
    };
    HomePageRefreshNotifier._refreshMessage = () {
      if (!mounted) return;
      _updateMessageDate();
    };
    _subscription = EventBus.stream.listen((event) {
      _updateMessageDate();
    });
  }

  Future<void> _prepareData() async {
    Worker.syncGlobalGroup();
  }

  Future<void> _startWs() async {
    Worker.startTaskWebSocket();
  }

  Future<void> _updateUserInfo() async {
    await Worker.syncAllUser();
    final result = await ProfileStorage.getUserList();
    if (result != null) {
      _userInfoList.clear();
      _userInfoList.addAll(result);
      setState(() {});
    }
  }

  Future<void> _loadMine() async {
    _username = await ProfileStorage.getName();
    _id = await ProfileStorage.getId();
    _ts = await ProfileStorage.getAvatarTs();
    _userType = await TokenStorage.getTokenUserType();
    setState(() {});
  }

  Future<void> _updateMine() async {
    await Worker.syncMyData();
    _loadMine();
  }

  Future<void> _updateTaskData() async {
    _taskList.clear();
    _taskList.addAll((await TaskStorage.getAllTask()).reversed.toList());
    setState(() {});
  }

  Future<void> _updateMessageDate() async {
    _messageList.clear();
    _messageList.addAll(
      (await MessageStorage.getAllMessage()).reversed.toList(),
    );
    setState(() {});
  }

  Future<void> _updateAllData() async {
    _updateUserInfo();
    _updateTaskData();
    _updateMessageDate();
    _updateMine();
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
              messageList: _messageList,
              onRefresh: () async {
                await _updateMessageDate();
              },
            ),
            TaskView(
              taskList: _taskList,
              onRefresh: () async {
                await _updateTaskData();
              },
            ),
            UserView(
              userType: _userType,
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
          ],
        ),
      ],
    );
  }

  Widget _buildAccessSignal() {
    late (String, Color, Color) r;
    if (userTypeStyleMap.containsKey(_userType)) {
      r = userTypeStyleMap[_userType]!;
    } else {
      r = userTypeStyleMap["guest"]!;
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
        currentIndex: _currentIndex,
        selectedLabelStyle: selectedTextStyle,
        unselectedLabelStyle: unselectedTextStyle,
        items: _bottomItemOptions
            .map(
              (record) => BottomNavigationBarItem(
                icon: Icon(record.$1),
                activeIcon: Icon(record.$2),
                label: record.$3,
              ),
            )
            .toList(),
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
