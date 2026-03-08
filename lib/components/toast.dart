import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

Future showToast({
  required String msg,
  Duration duration = const Duration(seconds: 1),
  Alignment? align,
}) async {
  final actualAlign = align ?? (Alignment.topCenter + const Alignment(0, 0.25));

  final completer = Completer();
  BotToast.showText(
    text: msg,
    duration: duration,
    align: actualAlign,
    contentColor: const Color.fromRGBO(158, 158, 158, 0.8),
    textStyle: const TextStyle(
      fontSize: 16,
      color: Colors.white,
      fontFamily: "SmileySans",
    ),
    onClose: () => completer.complete(),
  );
  return completer.future;
}
