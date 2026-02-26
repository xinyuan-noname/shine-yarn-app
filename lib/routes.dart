import 'package:flutter/material.dart';
import 'package:shine/pages/admin.dart';
import 'package:shine/pages/home.dart';
import 'package:shine/pages/login.dart';
import 'package:shine/pages/password.dart';
import 'package:shine/pages/profile.dart';
import 'package:shine/pages/register.dart';
import 'package:shine/pages/reset_password.dart';

final Map<String, WidgetBuilder> appRouters = {
  "/login": (_) => LoginPage(),
  '/register': (_) => RegisterPage(),
  "/home": (_) => HomePage(),
  "/profile": (_) => ProfilePage(),
  '/admin': (_) => AdminPage(),
  '/password': (_) => PasswordPage(),
  "/reset_password": (_) => ResetPasswordPage(),
};
final globalNavigatorKey = GlobalKey<NavigatorState>();
// ignore: prefer_function_declarations_over_variables
final clearOldRouter = (Route<dynamic> router) => false;
