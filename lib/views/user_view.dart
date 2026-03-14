import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/user_info_card.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_auth.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/share.dart';
import 'package:shine/utils/server.dart';

class UserView extends StatelessWidget {
  final List userInfoList;
  final ValueNotifier<String> message;
  final RefreshCallback onRefresh;
  const UserView({
    super.key,
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
      padding: viewPadding,
      itemBuilder: (context, index) {
        if (userInfoList.isEmpty) {
          return Container(
            alignment: Alignment.center,
            child: Text(
              "暂无用户数据",
              style: viewEmptyTextStyle,
            ),
          );
        }
        final userInfo = userInfoList[index];
        final id = userInfo["id"];
        final userInfoCard = UserInfoCard(
          userInfo: userInfo,
          onIssuePswdKey: ApiService.userType == "admin"
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
        final result = await ApiAuth.issuePasswordKey(id);
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
      Navigator.of(context).pop();
    }
    if (success) {
      await sharePswdKey(id: id, passwordKey: passwordKey);
    }
  }
}
