import 'package:flutter/material.dart';
import 'package:shine/theme.dart';

class SplashPage extends StatelessWidget {

  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: bgColorLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "闪纺",
            style: TextStyle(
              fontSize: 64,
              fontFamily: "SmileySans",
              color: Colors.white30,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 20,
                  color: Colors.amberAccent,
                ),
                Shadow(offset: Offset(3, 3), color: mainColorPurple),
                Shadow(offset: Offset(-3, -3), color: mainColorPurple),
              ],
            ),
          ),
          Text(
            "by Shine Yarn",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 4,
                  color: Colors.orange.shade200.withAlpha(135),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
