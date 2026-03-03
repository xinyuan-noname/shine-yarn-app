import 'package:flutter/material.dart';

const bgColorLight = Color.fromRGBO(230, 240, 255, 1);
const bgColorLight80 = Color.fromRGBO(230, 240, 255, 0.80);
const bgColorLight60 = Color.fromRGBO(230, 240, 255, 0.60);
const mainColorGreenBule = Color.fromARGB(255, 7, 247, 255);
const mainColorGreenBule60 = Color.fromRGBO(7, 247, 255, 0.60);
const mainColorGreenBule50 = Color.fromRGBO(7, 247, 255, 0.50);
const mainColorGreenBule40 = Color.fromRGBO(7, 247, 255, 0.40);
const mainColorGreenBule30 = Color.fromRGBO(7, 247, 255, 0.30);
const darkColorPurple = Color.fromRGBO(107, 99, 187, 1);
const mainColorPurple = Color.fromRGBO(167, 157, 255, 1);
const mainColorPurple90 = Color.fromRGBO(167, 157, 255, 0.9);
const mainColorPurple80 = Color.fromRGBO(167, 157, 255, 0.8);
const mainColorPurple70 = Color.fromRGBO(167, 157, 255, 0.7);
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
const TextStyle titleTextStyle = TextStyle(fontWeight: FontWeight.w600);
const double profileFontSize = 18;
const TextStyle profileKeyTextStyle = TextStyle(fontSize: profileFontSize);
const TextStyle profileValueTextStyle = TextStyle(
  fontSize: profileFontSize,
  color: Colors.grey,
);
const EdgeInsetsGeometry profilePadding = EdgeInsets.only(
  left: 20,
  right: 20,
  top: 10,
  bottom: 10,
);

const TextStyle bottomListTitleTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 20,
);
const TextStyle bottomSheetGridTitleTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 12,
  color: mainColorGreenBule,
);

const hintStyle = TextStyle(fontFamily: "SmileySans", color: bgColorLight60);
const inputStyle = TextStyle(fontFamily: "SmileySans", color: bgColorLight);
const labelStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 16,
  fontWeight: FontWeight.w500,
);
