  import 'package:flutter/material.dart';
import 'package:shine/theme.dart';

Widget buildBottomItem({
    required IconData icon,
    required String title,
    GestureTapCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          Text(title, style: bottomTitleTextStyle, textAlign: TextAlign.center),
        ],
      ),
    );
  }