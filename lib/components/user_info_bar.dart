import 'package:flutter/material.dart';

class UserInfoBar extends StatelessWidget {
  final GestureTapCallback? onTap;
  final String id;
  final String username;
  final Icon? suffixIcon;
  final BoxDecoration? decoration;
  final TextStyle usernameStyle;
  final TextStyle idStyle;
  final EdgeInsetsGeometry margin;
  const UserInfoBar({
    super.key,
    required this.id,
    required this.username,
    this.onTap,
    this.suffixIcon,
    this.decoration,
    this.usernameStyle = const TextStyle(fontFamily: "SmileySans"),
    this.idStyle = const TextStyle(fontFamily: "SmileySans"),
    this.margin = const EdgeInsets.symmetric(vertical: 1),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: decoration,
        child: Row(
          children: [
            if (suffixIcon != null) suffixIcon!,
            Text(username, style: usernameStyle),
            SizedBox(width: 5),
            Text(id, style: idStyle),
          ],
        ),
      ),
    );
  }
}
