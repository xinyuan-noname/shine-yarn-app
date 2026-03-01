import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/routes.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/storage/token_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/views/user.dart';
import 'package:shine/worker/worker.dart';

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
    (Icons.group_outlined, Icons.group, "用户"),
  ];

  @override
  void initState() {
    super.initState();
    _update();
    _updateUserInfo();
  }

  Future<void> _updateUserInfo() async {
    await Worker.scheduleAllUser();
    final result = await ProfileStorage.getUserList();
    if (result != null) {
      _userInfoList = result;
      setState(() {});
    }
  }

  Future<void> _fetchData() async {
    await Worker.scheduleMyData();
  }

  Future<void> _update() async {
    _username = await ProfileStorage.getName();
    _avatarPath = await ProfileStorage.getAvatarPath();
    _id = await ProfileStorage.getId();
    _userType = await TokenStorage.getTokenUserType();
    setState(() {});
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
      bottom: bottomLine,
    );
  }

  Widget _buildBottombar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
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
    );
  }
}
