import 'package:flutter/material.dart';
import 'package:shine/pages/admin_page.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/pages/login_page.dart';
import 'package:shine/pages/notice_upload_page.dart';
import 'package:shine/pages/password_page.dart';
import 'package:shine/pages/profile_page.dart';
import 'package:shine/pages/register_page.dart';
import 'package:shine/pages/reset_password_page.dart';
import 'package:shine/pages/semester_page.dart';
import 'package:shine/pages/task_check_page.dart';
import 'package:shine/pages/task_draw_page.dart';
import 'package:shine/pages/task_upload_page.dart';
import 'package:shine/pages/task_vote_detail_page.dart';
import 'package:shine/pages/task_vote_list_page.dart';
import 'package:shine/pages/task_vote_page.dart';
import 'package:shine/pages/to_do_page.dart';
import 'package:shine/pages/tool_convert_to_pdf_page.dart';
import 'package:shine/pages/tool_base_converter_page.dart';
import 'package:shine/pages/tool_function_transformer_page.dart';
import 'package:shine/pages/tool_encoder_page.dart';
import 'package:shine/pages/tool_karnaugh_map_page.dart';
import 'package:shine/pages/view_image_page.dart';
import 'package:shine/pages/view_pdf_page.dart';

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
  "/task/vote/list": (_) => const TaskVoteListPage(),
  "/task/vote/detail": (_) => const TaskVoteDetailPage(),
  "/task/upload": (_) => TaskUploadPage(),
  "/view/pdf": (_) => ViewPdfPage(),
  '/view/image': (_) => ViewImagePage(),
  '/tool/convert/pdf': (_) => ToolConvertToPdfPage(),
    '/tool/karnaugh': (_) => const ToolKarnaughMapPage(),
    '/tool/function_transformer': (_) => const ToolFunctionTransformerPage(),
    '/tool/encoder': (_) => const ToolEncoderPage(),
    '/tool/base_converter': (_) => const ToolBaseConverterPage(),
  '/to_do': (_) => ToDoPage(),
  "/notice/upload": (_) => NoticeUploadPage(),
};
final globalNavigatorKey = GlobalKey<NavigatorState>();
