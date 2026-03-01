import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/user_info_card.dart';
import 'package:shine/services/admin.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/server.dart';

class UserView extends StatelessWidget {
  final String? userType;
  final List userInfoList;
  final ValueNotifier<String> message;

  final RefreshCallback onRefresh;
  const UserView({
    super.key,
    this.userType,
    required this.userInfoList,
    required this.message,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: RefreshIndicator(
            color: mainColorPurple90,
            backgroundColor: bgColorLight,
            onRefresh: onRefresh,
            child: _buildViewList(),
          ),
        ),
      ],
    );
  }

  Widget _buildViewList() {
    return ListView.builder(
      itemCount: max(userInfoList.length, 1),
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        if (userInfoList.isEmpty) {
          return Container(
            alignment: Alignment.center,
            child: Text(
              "暂无用户数据",
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          );
        }
        final userInfo = userInfoList[index];
        final id = userInfo["id"];
        final userInfoCard = UserInfoCard(
          userInfo: userInfo,
          onIssuePswdKey: userType == "admin"
              ? () {
                  _issuePasswordKey(id, context);
                }
              : null,
        );
        return userInfoCard;
      },
    );
  }

  Future<void> _issuePasswordKey(String id, BuildContext context) async {
    message.value = "";
    late String passwordKey;
    showMessageDialog(context, message);
    final success = await sendRequestAndChangeMessage(
      message,
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
}
