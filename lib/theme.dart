import 'package:flutter/material.dart';

const bgColorLight = Color.fromRGBO(230, 240, 255, 1);
const bgColorLight60 = Color.fromRGBO(230, 240, 255, 0.60);
const mainColorGreenBule = Color.fromARGB(255, 7, 247, 255);
const mainColorGreenBule60 = Color.fromRGBO(7, 247, 255, 0.60);
const mainColorGreenBule50 = Color.fromRGBO(7, 247, 255, 0.50);
const mainColorGreenBule40 = Color.fromRGBO(7, 247, 255, 0.40);
const mainColorGreenBule30 = Color.fromRGBO(7, 247, 255, 0.30);
const mainColorPurple = Color.fromRGBO(167, 157, 255, 1);
const mainColorPurple60 = Color.fromRGBO(167, 157, 255, 0.6);
const mainColorPurple50 = Color.fromRGBO(167, 157, 255, 0.5);
const mainColorPurple40 = Color.fromRGBO(167, 157, 255, 0.4);

final inputDecorationLight = InputDecoration(
  contentPadding: EdgeInsets.only(left: 10),
  filled: true,
  fillColor: mainColorGreenBule30,
  border: OutlineInputBorder(
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.circular(15),
  ),
);

const double smallFontSize = 14;