import 'package:flutter/material.dart';

const double normalIconSize = 24;
const double middileIconSize = 48;
const double largeIconSize = 48;
const double hugeIconSize = 72;

const deepPurpleShadow = Shadow(color: darkColorPurple, blurRadius: 5);

const greyBoxShadow = BoxShadow(
  color: mainColorGrey80,
  blurRadius: 5,
  spreadRadius: 1,
);

const bgColorLight = Color.fromRGBO(230, 240, 255, 1);
const bgColorLight80 = Color.fromRGBO(230, 240, 255, 0.80);
const bgColorLight60 = Color.fromRGBO(230, 240, 255, 0.60);

const deepColorBlue = Color.fromARGB(255, 0, 187, 255);
const deepColorBlue80 = Color.fromARGB(204, 0, 187, 255);

const mainColorGreenBlue = Color.fromARGB(255, 7, 247, 255);
const mainColorGreenBlue80 = Color.fromRGBO(7, 247, 255, 0.80);
const mainColorGreenBlue60 = Color.fromRGBO(7, 247, 255, 0.60);
const mainColorGreenBlue50 = Color.fromRGBO(7, 247, 255, 0.50);
const mainColorGreenBlue40 = Color.fromRGBO(7, 247, 255, 0.40);
const mainColorGreenBlue30 = Color.fromRGBO(7, 247, 255, 0.30);

const deepColorPurple = Color.fromARGB(255, 107, 99, 187);
const deepColorPurple90 = Color.fromRGBO(107, 99, 187, 0.9);
const deepColorPurple80 = Color.fromRGBO(107, 99, 187, 0.8);
const deepColorPurple70 = Color.fromRGBO(107, 99, 187, 0.7);
const deepColorPurple60 = Color.fromRGBO(107, 99, 187, 0.6);
const deepColorPurple50 = Color.fromRGBO(107, 99, 187, 0.5);
const deepColorPurple40 = Color.fromRGBO(107, 99, 187, 0.4);
const deepColorPurple30 = Color.fromRGBO(107, 99, 187, 0.3);

const darkColorPurple = Color.fromARGB(255, 52, 49, 84);
const darkColorPurple90 = Color.fromARGB(230, 52, 49, 84);

const mainColorPurple = Color.fromARGB(255, 167, 157, 255);
const mainColorPurple95 = Color.fromARGB(241, 167, 157, 255);
const mainColorPurple90 = Color.fromARGB(230, 167, 157, 255);
const mainColorPurple80 = Color.fromARGB(204, 167, 157, 255);
const mainColorPurple70 = Color.fromARGB(179, 167, 157, 255);
const mainColorPurple60 = Color.fromARGB(153, 167, 157, 255);
const mainColorPurple50 = Color.fromARGB(128, 167, 157, 255);
const mainColorPurple40 = Color.fromARGB(102, 167, 157, 255);
const mainColorPurple30 = Color.fromARGB(77, 167, 157, 255);

const mainColorGrey = Color.fromARGB(255, 158, 158, 158);
const mainColorGrey80 = Color.fromARGB(204, 158, 158, 158);
const mainColorGrey60 = Color.fromARGB(153, 158, 158, 158);
const mainColorGrey40 = Color.fromARGB(102, 158, 158, 158);
const mainColorGrey20 = Color.fromARGB(51, 158, 158, 158);

const mainColorRed = Color.fromRGBO(255, 83, 83, 1);
const mainColorRed70 = Color.fromARGB(179, 255, 83, 83);
const mainColorRed50 = Color.fromARGB(128, 255, 83, 83);
const mainColorRed20 = Color.fromARGB(51, 255, 83, 83);
const deepColorRed = Color.fromRGBO(255, 17, 0, 1);

const mainColorOrange = Color.fromRGBO(255, 204, 128, 1);
const mainColorOrange50 = Color.fromRGBO(255, 204, 128, 0.5);

final inputDecorationLight = InputDecoration(
  contentPadding: EdgeInsets.only(left: 10),
  filled: true,
  fillColor: mainColorGreenBlue30,
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
  color: mainColorGreenBlue,
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
  color: mainColorGreenBlue,
  fontSize: 20,
);
const expansionListTitleStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 20,
  fontWeight: FontWeight.w500,
);
const expansionListTitleLineThroughStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 20,
  color: mainColorGrey80,
  fontWeight: FontWeight.w500,
  decoration: TextDecoration.lineThrough,
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
const TextStyle textFieldStyle = TextStyle(
  fontFamily: 'SmileySans',
  fontSize: 19,
);
const TextStyle textFieldHintStyle = TextStyle(
  fontFamily: 'SmileySans',
  fontSize: 19,
  color: Colors.grey,
);
const TextStyle textFieldSmallStyle = TextStyle(
  fontFamily: 'SmileySans',
  fontSize: 15,
);
const TextStyle textFieldHintSmallStyle = TextStyle(
  fontFamily: 'SmileySans',
  fontSize: 15,
  color: Colors.grey,
);

const TextStyle viewEmptyTextStyle = TextStyle(
  fontSize: 20,
  color: Colors.grey,
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
const purpleLinearGradientReversed = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [mainColorPurple, deepColorPurple],
);
const purpleLinearGradientStrong = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [darkColorPurple, deepColorPurple, mainColorPurple],
);
const blueLinearGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [deepColorBlue, mainColorGreenBlue],
);
const blueLinearGradient80 = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [deepColorBlue80, mainColorGreenBlue80],
);
const blueLinearGradientReversed = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [mainColorGreenBlue, deepColorBlue],
);
const whiteLinearGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Colors.white, bgColorLight],
);
const greyLinearGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Colors.grey, mainColorGrey80],
);
