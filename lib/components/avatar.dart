import 'package:flutter/material.dart';
import 'package:shine/theme.dart';

final defaultAvatar = Container(
  alignment: Alignment.center,
  height: 52,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: Colors.blue, width: 0.5),
    color: mainColorGreenBule40,
    boxShadow: [
      BoxShadow(
        color: const Color.fromRGBO(255, 255, 255, 0.2),
        spreadRadius: 1,
        blurRadius: 2,
        offset: Offset(0, 3), // changes position of shadow
      ),
    ],
  ),
  child: CircleAvatar(
    backgroundColor: mainColorGreenBule40,
    radius: 25,
    child: Text(
      "闪",
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        fontFamily: "SmileySans",
        color: Colors.white30,
        shadows: [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 20,
            color: Colors.amberAccent,
          ),
          Shadow(offset: Offset(1, 1), color: mainColorPurple),
          Shadow(offset: Offset(-1, -1), color: mainColorPurple),
        ],
      ),
    ),
  ),
);
