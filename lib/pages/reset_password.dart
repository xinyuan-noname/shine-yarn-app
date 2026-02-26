import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/user_info_card.dart';
import 'package:shine/services/auth.dart';
import 'package:shine/theme.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final List _userInfoList = [];
  @override
  void initState() {
    super.initState();
    Future(() async {
      final adminList = await ApiAuth.getAdminInfo();
      _userInfoList.addAll(adminList);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("更改密码", style: titleTextStyle),
        centerTitle: true,
        bottom: bottomLine,
      ),
      body: Column(
        children: [
          Text("请联系以下管理员，获得密码令牌以重置密码。"),
          Expanded(child: _buildViewList()),
          Text("已有令牌？请进行下一步"),
        ],
      ),
    );
  }

  Widget _buildViewList() {
    return ListView.builder(
      itemCount: max(_userInfoList.length, 1),
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        if (_userInfoList.isEmpty) {
          return Container(
            alignment: Alignment.center,
            child: Text(
              "暂无管理员数据",
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          );
        }
        final userInfo = _userInfoList[index];
        final userInfoCard = UserInfoCard(userInfo: userInfo);
        return userInfoCard;
      },
    );
  }
}
