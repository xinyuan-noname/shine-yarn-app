import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'dart:math' as math;

import 'package:shine/theme.dart';

const double adminFontSize = 24;
const TextStyle adminUsernameTextStyle = TextStyle(
  fontFamily: 'SmileySans',
  fontSize: adminFontSize,
  color: mainColorGreenBule,
);

class UserInfoCard extends StatelessWidget {
  final Map<String, dynamic> userInfo;
  final bool? noOperation;
  final GestureTapCallback? onDelete;
  final GestureTapCallback? onEdit;
  final GestureTapCallback? onIssuePswdKey;
  final GestureTapCallback? onPress;
  final GestureLongPressCallback? onLongPress;
  const UserInfoCard({
    super.key,
    required this.userInfo,
    this.onDelete,
    this.onEdit,
    this.onIssuePswdKey,
    this.onLongPress,
    this.onPress,
    this.noOperation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onPress,
      child: Card(
        elevation: 2,
        color: mainColorPurple,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: mainColorGreenBule60,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: purpleLinearGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUsernameRow(),
                _buildIdRow(),
                if (userInfo.containsKey("gender")) _buildGenderRow(),
                if (userInfo["passwordRequired"] != null) _buildPasswordRow(),
                bottomLine,
                if (noOperation != true) _buildOperatorRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (onIssuePswdKey != null)
              GestureDetector(
                onTap: onIssuePswdKey,
                child: Container(
                  alignment: Alignment.center,
                  height: adminFontSize * 1.1,
                  decoration: BoxDecoration(
                    color: mainColorGreenBule60,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  child: Text(
                    "签发密码令牌",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'SmileySans',
                    ),
                  ),
                ),
              ),
          ],
        ),
        Row(
          children: [
            if (onEdit != null)
              GestureDetector(
                onTap: onEdit,
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: adminFontSize * 1.1,
                ),
              ),
            SizedBox(height: adminFontSize * 1.1, width: 15),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: adminFontSize * 1.1,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsernameRow() {
    return Row(
      children: [
        userInfo['userType'] == "admin"
            ? Icon(
                Icons.star,
                color: Colors.amberAccent,
                size: adminFontSize * 1.2,
              )
            : Icon(
                Icons.person,
                color: bgColorLight,
                size: adminFontSize * 1.2,
              ),
        const SizedBox(width: 5),
        Text(userInfo['username'] ?? "??", style: adminUsernameTextStyle),
        if (userInfo['position'] is String)
          Container(
            margin: EdgeInsets.only(left: 10),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
            decoration: BoxDecoration(
              gradient: redLinearGradientReversed,
              boxShadow: [
                BoxShadow(
                  color: bgColorLight60,
                  spreadRadius: 1,
                  offset: Offset(0.5, 0.5),
                ),
              ],
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Text(
              userInfo['position'],
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'SmileySans',
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIdRow() {
    return Row(
      children: [
        Text("学号", style: cardItemTextStyle),
        Text(":", style: cardItemTextStyle),
        const SizedBox(width: 5),
        Text(userInfo['id'], style: cardItemTextStyle),
      ],
    );
  }

  Widget _buildGenderRow() {
    return Row(
      children: [
        Text("性别", style: cardItemTextStyle),
        Text(":", style: cardItemTextStyle),
        const SizedBox(width: 5),
        Text(
          userInfo['gender'] == "male"
              ? "男"
              : userInfo["gender"] == "female"
              ? "女"
              : "无可奉告",
          style: cardItemTextStyle,
        ),
        Transform.rotate(
          angle: math.pi / 24,
          child: userInfo['gender'] == "male"
              ? Icon(
                  Icons.male_rounded,
                  color: bgColorLight80,
                  size: adminFontSize,
                )
              : userInfo["gender"] == "female"
              ? Transform.translate(
                  offset: const Offset(-3, 0),
                  child: Icon(
                    Icons.female_rounded,
                    color: bgColorLight80,
                    size: adminFontSize,
                  ),
                )
              : Transform.translate(
                  offset: const Offset(-4, 0),
                  child: Icon(
                    Icons.question_mark_rounded,
                    color: bgColorLight80,
                    size: adminFontSize,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPasswordRow() {
    return Row(
      children: [
        Text("强制密码登录", style: cardItemTextStyle),
        Text(":", style: cardItemTextStyle),
        const SizedBox(width: 5),
        Text(
          userInfo['passwordRequired'] == true ? "是" : "否",
          style: cardItemTextStyle,
        ),
      ],
    );
  }
}
