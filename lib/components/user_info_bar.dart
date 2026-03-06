import 'package:flutter/material.dart';
import 'package:shine/theme.dart';

class UserInfoBar extends StatelessWidget {
  final GestureTapCallback? onTap;
  final String id;
  final String username;
  final Icon? suffixIcon;
  final BoxDecoration? decoration;
  final TextStyle usernameStyle;
  final TextStyle idStyle;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  const UserInfoBar({
    super.key,
    required this.id,
    required this.username,
    this.onTap,
    this.suffixIcon,
    this.decoration = const BoxDecoration(gradient: whiteLinearGradient,borderRadius: BorderRadius.all(Radius.circular(2))),
    this.usernameStyle = const TextStyle(
      fontSize: 16,
      fontFamily: "SmileySans",
    ),
    this.idStyle = const TextStyle(fontSize: 16, fontFamily: "SmileySans"),
    this.margin = const EdgeInsets.symmetric(vertical: 1.5),
    this.padding = const EdgeInsets.all(1.5),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
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
