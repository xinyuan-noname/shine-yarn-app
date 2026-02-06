import 'package:flutter/material.dart';
import 'package:shine/pages/home.dart';
import 'package:shine/pages/login.dart';

final Map<String, WidgetBuilder> appRouters = {
  "/login": (_) => LoginPage(),
  "/home": (_) => HomePage()
};
final globalNavigatorKey = GlobalKey<NavigatorState>();