import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/input.dart';
import 'package:shine/extensions/text_editing.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/auth.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/server.dart';

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
  int _titleTapCount = 0;
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
              GestureDetector(
                onTap: () {
                  _titleTapCount++;
                  if (_titleTapCount >= 5) {
                    gotoAdminDialog(context);
                    _titleTapCount = 0;
                  }
                },
                child: Center(
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
                      _message.value = "正在发送登录请求";
                      showMessageDialog(context, _message);
                      final success = await _toLogin();
                      if (success) {
                        if (_controllers.asTextMap["username"] != null) {
                          await ProfileStorage.saveName(
                            _controllers.asTextMap["username"]!,
                          );
                        }
                        if (_controllers.asTextMap["id"] != null) {
                          await ProfileStorage.saveId(
                            _controllers.asTextMap["id"]!,
                          );
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          globalNavigatorKey.currentState
                              ?.pushNamedAndRemoveUntil(
                                '/home',
                                clearOldRouter,
                              );
                        }
                      } else if (context.mounted) {
                        Navigator.pop(context);
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
    return await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return await ApiAuth.login(_controllers.asTextMap);
      }),
      initMessageList: ["正在校验信息", "正在签发访问令牌", "正在签发刷新令牌"],
      messageList: ["处理其他登录请求中.", "处理其他登录请求中..", "处理其他登录请求中..."],
      successMessage: "登录成功",
      successMessageDuration: Duration(milliseconds: 300),
      failMessageDuration: Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controllers.disposeAll();
    _message.dispose();
  }
}
