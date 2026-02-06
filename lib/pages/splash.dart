import 'package:flutter/material.dart';
import 'package:shine/theme.dart';

class SplashPage extends StatelessWidget {
  final Widget slot;

  const SplashPage({super.key, required this.slot});
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: bgColorLight,
      child: slot,
    );
  }
}
