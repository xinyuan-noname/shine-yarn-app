import 'package:flutter/material.dart';
import 'package:shine/routes.dart';

bool isOnLoginPageGlobally() {
  final currentRoute = globalNavigatorKey.currentContext != null
      ? ModalRoute.of(globalNavigatorKey.currentContext!)?.settings.name
      : null;
  return currentRoute == '/login';
}

// ignore: prefer_function_declarations_over_variables
final clearOldRouter = (Route<dynamic> router) => false;

Future goToLoginGlobally() async {
  await globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
    '/login',
    clearOldRouter,
  );
}
