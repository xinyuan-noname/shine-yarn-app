import 'package:flutter/material.dart';
import 'package:shine/pages/home.dart';
import 'package:shine/pages/login.dart';
import 'package:shine/pages/profile.dart';

final Map<String, WidgetBuilder> appRouters = {
  "/login": (_) => LoginPage(),
  "/home": (_) => HomePage(),
  "/profile":(_)=>ProfilePage(),
};
final globalNavigatorKey = GlobalKey<NavigatorState>();