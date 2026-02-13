import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shine/components/input.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/auth.dart';
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
                      if (_formKey.currentState!.validate() &&
                          ApiService.isOk()) {
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
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => ValueListenableBuilder<String>(
                            valueListenable: _message,
                            builder: (_, text, __) => Dialog(
                              child: Container(
                                height: 64,
                                alignment: Alignment.center,
                                child: Text(text),
                              ),
                            ),
                          ),
                        );
                        final success = await _toLogin();
                      }
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
    final result = await Future.wait([
      Future(() async {
        return await ApiAuth.login(_controllers.asTextMap);
      }),
      Future(() async {
        const duration = 800;
        await Future.delayed(Duration(milliseconds: duration));
        _message.value = "正在校验信息";
        await Future.delayed(Duration(milliseconds: duration));
        _message.value = "正在签发访问令牌";
        await Future.delayed(Duration(milliseconds: duration));
        _message.value = "正在签发刷新令牌";
        return true;
      }),
    ]);
    if (result[0] == false) {
      _message.value = "登录失败";
      await Future.delayed(Duration(milliseconds: 500));
      ApiService.reinit();
      return false;
    } else if (result[0] == true) {
      _message.value = "登录成功";
      await Future.delayed(Duration(milliseconds: 300));
      return true;
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
