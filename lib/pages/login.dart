import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/input.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/auth.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final ValueNotifier<String> _message = ValueNotifier("正在发送登录请求");
  late final List<Input> _inputs;
  @override
  void initState() {
    super.initState();
    _inputs = [
      InputProps.number(
        label: "学号",
        name: "id",
        color: mainColorPurple,
        isRequired: true,
        gap: 5,
      ),
      InputProps.cnName(
        label: "姓名",
        name: "username",
        color: mainColorPurple,
        isRequired: true,
        gap: 5,
      ),
      InputProps.password(color: mainColorPurple, isLast: true),
    ].generateAndAssignController(_controllers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: const Text(
                  "学号姓名密码登录",
                  style: TextStyle(
                    color: Colors.white30,
                    fontFamily: "SmileySans",
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(offset: Offset(1, 1), color: mainColorPurple),
                      Shadow(offset: Offset(-1, -1), color: mainColorPurple),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Form(
                key: _formKey,
                child: Column(children: [..._inputs]),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      if (!ApiService.isOk) return;
                      _toLogin().then((success) {
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                        if (success && context.mounted) {
                          globalNavigatorKey.currentState
                              ?.pushNamedAndRemoveUntil(
                                '/home',
                                clearOldRouter,
                              );
                        }
                      });
                      showMessageDialog(context, _message);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColorPurple,
                      padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    ),
                    child: const Text(
                      "登录",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: "SmileySans",
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _toLogin() async {
    _message.value = "正在发送登录请求";
    String? result;
    await Future.wait([
      Future(() async {
        result = await ApiAuth.login(_controllers.asTextMap);
      }),
      Future(() async {
        const duration = 800;
        await Future.delayed(Duration(milliseconds: duration));
        if (result != null) return null;
        _message.value = "正在校验信息";
        await Future.delayed(Duration(milliseconds: duration));
        if (result != null) return null;
        _message.value = "正在签发访问令牌";
        await Future.delayed(Duration(milliseconds: duration));
        if (result != null) return null;
        _message.value = "正在签发刷新令牌";
      }),
    ]);
    if (result == null) {
      _message.value = "登录成功";
      if (_controllers.asTextMap["username"] != null) {
        await ProfileStorage.saveName(_controllers.asTextMap["username"]!);
      }
      if (_controllers.asTextMap["id"] != null) {
        await ProfileStorage.saveId(_controllers.asTextMap["id"]!);
      }
      await Future.delayed(Duration(milliseconds: 300));
      return true;
    } else {
      _message.value = result!;
      await Future.delayed(Duration(milliseconds: 500));
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controllers.disposeAll();
    _message.dispose();
  }
}

extension TextEditingControllerMap on Map<String, TextEditingController> {
  void disposeAll() {
    for (final controller in values) {
      controller.dispose();
    }
  }

  Map<String, String> get asTextMap {
    final map = <String, String>{};
    for (final entry in entries) {
      final name = entry.key, controller = entry.value;
      map[name] = controller.text;
    }
    return map;
  }

  String get asTextJSON {
    final map = <String, String>{};
    for (final entry in entries) {
      final name = entry.key, controller = entry.value;
      map[name] = controller.text;
    }
    return jsonEncode(map);
  }
}
