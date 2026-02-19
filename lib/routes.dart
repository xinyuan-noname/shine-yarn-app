import 'package:flutter/material.dart';
import 'package:shine/pages/admin.dart';
import 'package:shine/pages/home.dart';
import 'package:shine/pages/login.dart';
import 'package:shine/pages/profile.dart';

final Map<String, WidgetBuilder> appRouters = {
  "/login": (_) => LoginPage(),
  "/home": (_) => HomePage(),
  "/profile": (_) => ProfilePage(),
  '/admin': (_) => AdminPage(),
};
final globalNavigatorKey = GlobalKey<NavigatorState>();
// ignore: prefer_function_declarations_over_variables
final clearOldRouter = (Route<dynamic> router) => false;
