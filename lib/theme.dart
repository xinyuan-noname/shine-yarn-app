import 'package:flutter/material.dart';

const bgColorLight = Color.fromRGBO(230, 240, 255, 1);
const bgColorLight80 = Color.fromRGBO(230, 240, 255, 0.80);
const bgColorLight60 = Color.fromRGBO(230, 240, 255, 0.60);

const deepColorBlue = Color.fromARGB(255, 0, 187, 255);

const mainColorGreenBule = Color.fromARGB(255, 7, 247, 255);
const mainColorGreenBule60 = Color.fromRGBO(7, 247, 255, 0.60);
const mainColorGreenBule50 = Color.fromRGBO(7, 247, 255, 0.50);
const mainColorGreenBule40 = Color.fromRGBO(7, 247, 255, 0.40);
const mainColorGreenBule30 = Color.fromRGBO(7, 247, 255, 0.30);

const deepColorPurple = Color.fromRGBO(107, 99, 187, 1);
const deepColorPurple90 = Color.fromRGBO(107, 99, 187, 0.9);
const deepColorPurple80 = Color.fromRGBO(107, 99, 187, 0.8);
const deepColorPurple70 = Color.fromRGBO(107, 99, 187, 0.7);
const deepColorPurple60 = Color.fromRGBO(107, 99, 187, 0.6);
const deepColorPurple50 = Color.fromRGBO(107, 99, 187, 0.5);
const deepColorPurple40 = Color.fromRGBO(107, 99, 187, 0.4);
const deepColorPurple30 = Color.fromRGBO(107, 99, 187, 0.3);
const darkColorPurple = Color.fromRGBO(52, 49, 84, 1);

const mainColorPurple = Color.fromRGBO(167, 157, 255, 1);
const mainColorPurple90 = Color.fromRGBO(167, 157, 255, 0.9);
const mainColorPurple80 = Color.fromRGBO(167, 157, 255, 0.8);
const mainColorPurple70 = Color.fromRGBO(167, 157, 255, 0.7);
const mainColorPurple60 = Color.fromRGBO(167, 157, 255, 0.6);
const mainColorPurple50 = Color.fromRGBO(167, 157, 255, 0.5);
const mainColorPurple40 = Color.fromRGBO(167, 157, 255, 0.4);

const mainColorRed = Color.fromRGBO(255, 83, 83, 1);
const deepColorRed = Color.fromRGBO(255, 17, 0, 1);

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

const TextStyle bottomListTitleTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 20,
);
const TextStyle bottomSheetGridTitleTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 12,
  color: mainColorGreenBule,
);
const TextStyle bottomTitleTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 12,
  color: Colors.grey,
);

const hintStyle = TextStyle(fontFamily: "SmileySans", color: bgColorLight60);
const inputStyle = TextStyle(fontFamily: "SmileySans", color: bgColorLight);
const labelStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

const listTitleStyle = TextStyle(
  fontFamily: "SmileySans",
  color: mainColorGreenBule,
  fontSize: 20,
);
const expansionListTitleStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 20,
  fontWeight: FontWeight.w500
);

const TextStyle cardItemTextStyle = TextStyle(
  fontFamily: 'SmileySans',
  fontSize: 18,
  color: bgColorLight80,
  fontWeight: FontWeight.w300,
  letterSpacing: 1.2,
);

const TextStyle tabLabelStyle = TextStyle(
  fontFamily: 'SmileySans',
  fontSize: 19.2,
  letterSpacing: 1.2,
);

const TextStyle purpleButtonStyle = TextStyle(
  fontFamily: 'SmileySans',
  fontSize: 19.2,
);

const bodyPadding = EdgeInsets.symmetric(vertical: 10, horizontal: 20);
const viewPadding = EdgeInsets.all(16);

const redLinearGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [mainColorRed, deepColorRed],
);
const redLinearGradientReversed = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [deepColorRed, mainColorRed],
);
const purpleLinearGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [deepColorPurple, mainColorPurple],
);
const purpleLinearGradientLight = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [deepColorPurple40, mainColorPurple40],
);
const blueLinearGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [deepColorBlue, mainColorGreenBule],
);
const blueLinearGradientReversed = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [mainColorGreenBule, deepColorBlue],
);
const whiteLinearGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Colors.white, bgColorLight],
);
