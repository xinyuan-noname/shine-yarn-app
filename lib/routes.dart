import 'package:flutter/material.dart';
import 'package:shine/pages/admin_page.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/pages/login_page.dart';
import 'package:shine/pages/password_page.dart';
import 'package:shine/pages/profile_page.dart';
import 'package:shine/pages/register_page.dart';
import 'package:shine/pages/reset_password_page.dart';

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
