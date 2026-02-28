import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/user_info_card.dart';
import 'package:shine/services/admin.dart';
import 'package:shine/services/profiles.dart';
import 'package:shine/storage/token_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/server.dart';

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final ValueNotifier<String> _message = ValueNotifier("");
  List _userInfoList = [];
  String _myUserType = "guest";
  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _updateUserType();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: RefreshIndicator(
            color: mainColorPurple90,
            backgroundColor: bgColorLight,
            child: _buildViewList(),
            onRefresh: () async {
              await _getUserInfo();
            },
          ),
        ),
      ],
    );
  }

  Future<void> _getUserInfo() async {
    final result = await ApiProfiles.getUserInfo();
    if (result == null) {
      Future.delayed(Duration(milliseconds: 500));
      await ApiProfiles.getUserInfo();
      return;
    }
    _userInfoList = result;
    setState(() {});
  }

  Future<void> _updateUserType() async {
    _myUserType = await TokenStorage.getTokenUserType();
    setState(() {});
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
              "暂无用户数据",
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          );
        }
        final userInfo = _userInfoList[index];
        final id = userInfo["id"];
        final userInfoCard = UserInfoCard(
          userInfo: userInfo,
          onIssuePswdKey: _myUserType == "admin"
              ? () {
                  _issuePasswordKey(id);
                }
              : null,
        );
        return userInfoCard;
      },
    );
  }

  Future<void> _issuePasswordKey(id) async {
    _message.value = "";
    late String passwordKey;
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        final result = await ApiAdmin.issuePasswordKey(id);
        if (result is String) return result;
        if (result is Map && result["passwordKey"] is String) {
          passwordKey = result["passwordKey"];
          return null;
        }
        return "签发失败";
      }),
      initMessageList: [],
      messageList: ["正在为$id签发密码令牌.", "正在为$id签发密码令牌..", "正在为$id签发密码令牌..."],
      successMessage: "签发成功",
    );
    if (context.mounted) {
      Navigator.pop(context);
    }
    if (success) {
      await Clipboard.setData(ClipboardData(text: "$id的密码令牌: $passwordKey"));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("已经$id的密码令牌复制到剪切板中")));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("令牌为: $passwordKey")));
    }
  }

  @override
  void dispose() {
    super.dispose();
    _message.dispose();
  }
}
