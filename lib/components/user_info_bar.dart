import 'package:flutter/material.dart';

class UserInfoBar extends StatelessWidget {
  final GestureTapCallback? onTap;
  final String id;
  final String username;
  final Icon? suffixIcon;
  final BoxDecoration? decoration;
  const UserInfoBar({
    super.key,
    required this.id,
    required this.username,
    this.onTap,
    this.suffixIcon,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: decoration,
        child: Row(
          children: [
            if (suffixIcon != null) suffixIcon!,
            Text(username),
            Text(id),
          ],
        ),
      ),
    );
  }
}
