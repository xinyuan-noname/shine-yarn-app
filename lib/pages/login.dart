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

const labelStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 16,
  fontWeight: FontWeight.w500,
);
const hintStyle = TextStyle(fontFamily: "SmileySans", color: bgColorLight60);
const inputStyle = TextStyle(fontFamily: "SmileySans", color: bgColorLight);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

const double gap = 40;

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
        labelStyle: labelStyle,
        hintStyle: hintStyle,
        inputStyle: inputStyle,
        color: mainColorPurple90,
        isRequired: true,
        gap: gap,
      ),
      InputProps.cnName(
        label: "姓名",
        name: "username",
        labelStyle: labelStyle,
        hintStyle: hintStyle,
        inputStyle: inputStyle,
        color: mainColorPurple90,
        isRequired: true,
        gap: gap,
      ),
      InputProps.password(
        hintStyle: hintStyle,
        color: mainColorPurple90,
        labelStyle: labelStyle,
        inputStyle: inputStyle,
        isLast: true,
      ),
    ].generateAndAssignController(_controllers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: GestureDetector(
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
      ),
      body: SafeArea(
        child: Container(
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              Form(
                key: _formKey,
                child: Column(children: [..._inputs]),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: bgColorLight60,
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
                await ProfileStorage.saveId(_controllers.asTextMap["id"]!);
              }
              if (context.mounted) {
                Navigator.pop(context);
                globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  '/home',
                  clearOldRouter,
                );
              }
            } else if (context.mounted) {
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            side: BorderSide(color: mainColorPurple80, width: 2.0),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: const Text(
            "登录",
            style: TextStyle(
              color: darkColorPurple,
              fontSize: 20,
              fontWeight: FontWeight.w300,
            ),
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
