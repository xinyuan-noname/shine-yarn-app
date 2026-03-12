import 'package:flutter/material.dart';
import 'package:shine/pages/admin_page.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/pages/login_page.dart';
import 'package:shine/pages/password_page.dart';
import 'package:shine/pages/profile_page.dart';
import 'package:shine/pages/register_page.dart';
import 'package:shine/pages/reset_password_page.dart';
import 'package:shine/pages/semester_page.dart';
import 'package:shine/pages/task_check_page.dart';
import 'package:shine/pages/task_draw_page.dart';
import 'package:shine/pages/task_upload_page.dart';
import 'package:shine/pages/task_vote_page.dart';

final Map<String, WidgetBuilder> appRouters = {
  "/login": (_) => LoginPage(),
  '/register': (_) => RegisterPage(),
  "/home": (_) => HomePage(),
  "/profile": (_) => ProfilePage(),
  '/admin': (_) => AdminPage(),
  '/admin/semester': (_) => SemesterPage(),
  '/password': (_) => PasswordPage(),
  "/reset/password": (_) => ResetPasswordPage(),
  "/task/check": (_) => TaskCheckPage(),
  "/task/draw": (_) => TaskDrawPage(),
  "/task/vote": (_) => TaskVotePage(),
  "/task/upload": (_) => TaskUploadPage(),
};
final globalNavigatorKey = GlobalKey<NavigatorState>();
