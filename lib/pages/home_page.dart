import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/bottom_sheet.dart';
import 'package:shine/components/line.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/ws.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/storage/token_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/views/message_view.dart';
import 'package:shine/views/user_view.dart';
import 'package:shine/worker/worker.dart';

const selectedTextStyle = TextStyle(fontFamily: "SmileySans");
const unselectedTextStyle = TextStyle(fontFamily: "SmileySans");
const userTypeStyleList = [
  ("访客", Colors.grey, Color.fromRGBO(255, 255, 255, 0.5)),
  ("用户", Colors.lightGreen, Color.fromRGBO(255, 255, 255, 0.8)),
  ("管理员", Colors.amber, Color.fromRGBO(255, 255, 255, 0.9)),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _avatarPath;
  String _username = "???";
  String _id = "??????????";
  int _currentIndex = 0;
  List _userInfoList = [];
  String _userType = "guest";
  final ValueNotifier<String> _message = ValueNotifier("");
  final _bottomItemOptions = [
    (Icons.task_outlined, Icons.task, "任务"),
    (Icons.message_outlined, Icons.message, "消息"),
    (Icons.group_outlined, Icons.group, "用户"),
  ];

  @override
  void initState() {
    super.initState();
    _update();
    _updateUserInfo();
    _startWs();
    _prepareData();
  }

  Future<void> _startWs() async {
    await WebSocketServer.init();
    Worker.startTaskWebSocket();
  }

  Future<void> _updateUserInfo() async {
    await Worker.syncAllUser();
    final result = await ProfileStorage.getUserList();
    if (result != null) {
      _userInfoList = result;
      setState(() {});
    }
  }

  Future<void> _fetchData() async {
    await Worker.syncMyData();
  }

  Future<void> _update() async {
    _username = await ProfileStorage.getName();
    _avatarPath = await ProfileStorage.getAvatarPath();
    _id = await ProfileStorage.getId();
    _userType = await TokenStorage.getTokenUserType();
    setState(() {});
  }

  Future<void> _prepareData() async {
    Worker.syncGlobalGroup();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> viewList = [
      RefreshIndicator(
        color: mainColorPurple90,
        backgroundColor: bgColorLight,
        child: ListView.builder(
          itemCount: 1,
          itemBuilder: (context, index) {
            return ListTile(title: Text('Item $index'));
          },
        ),
        onRefresh: () async {
          await _fetchData();
          await _update();
        },
      ),
      MessageView(),
      UserView(
        userType: _userType,
        userInfoList: _userInfoList,
        message: _message,
        onRefresh: () async {
          await _updateUserInfo();
        },
      ),
    ];
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(child: viewList[_currentIndex]),
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
                    await _update();
                  }
                },
                child: _avatarPath != null
                    ? CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 25,
                        backgroundImage: FileImage(File(_avatarPath!)),
                      )
                    : defaultAvatar25,
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
                      SizedBox(width: 3),
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
        if (_currentIndex == 0)
          IconButton(
            onPressed: () {
              showTaskGridBottomSheet(context);
            },
            icon: Icon(Icons.add, size: 32),
          ),
      ],
    );
  }

  Widget _buildAccessSignal() {
    late (String, Color, Color) r;
    if (_userType == "admin") {
      r = userTypeStyleList[2];
    } else if (_userType == "user") {
      r = userTypeStyleList[1];
    } else {
      r = userTypeStyleList[0];
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
}
