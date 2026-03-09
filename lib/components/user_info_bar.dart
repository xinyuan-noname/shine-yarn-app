import 'package:flutter/material.dart';
import 'package:shine/theme.dart';

class UserInfoBar extends StatelessWidget {
  final GestureTapCallback? onTap;
  final DismissDirectionCallback? onDismissed;
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
    this.decoration = const BoxDecoration(
      gradient: whiteLinearGradient,
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
    this.usernameStyle = const TextStyle(
      fontSize: 16,
      fontFamily: "SmileySans",
    ),
    this.idStyle = const TextStyle(fontSize: 16, fontFamily: "SmileySans"),
    this.margin = const EdgeInsets.symmetric(vertical: 2),
    this.padding = const EdgeInsets.all(1.5),
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
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
    return onDismissed == null
        ? content
        : Dismissible(
            onDismissed: onDismissed,
            key: key ?? Key('user-info-bar-$id'),
            child: content,
          );
  }
}
