import 'package:flutter/material.dart';
import 'package:shine/theme.dart';

final Column firstViewLight = Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(
      "闪纺",
      style: TextStyle(
        fontFamily: "SmileySans",
        fontSize: 64,
        color: mainColorGreenBule,
        shadows: [
          Shadow(offset: Offset(1, 1), blurRadius: 20, color: Colors.grey),
          Shadow(
            offset: Offset(2, 2),
            blurRadius: 10,
            color: mainColorPurple
          ),
        ],
      ),
    ),
    Text(
      "by Shine Yarn",
      style: TextStyle(
        fontSize: 6,
        fontWeight: FontWeight.bold,
        color: Color.fromARGB(255, 190, 130, 255),
        shadows: [
          Shadow(offset: Offset(1, 2), blurRadius: 5, color: Colors.redAccent),
        ],
      ),
    ),
  ],
);
