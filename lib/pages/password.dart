import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/input.dart';
import 'package:shine/components/line.dart';
import 'package:shine/extensions/text_editing.dart';
import 'package:shine/services/api_auth.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/server.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final ValueNotifier<String> _message = ValueNotifier("正在发送更改密码请求");
  late final List<Input> _inputs;
  @override
  void initState() {
    super.initState();
    _inputs = [
      InputProps.password(
        label: "新密码",
        name: "newPassword",
        isRequired: true,
        labelStyle: TextStyle(fontSize: 18),
        decoration: InputDecoration(
          hintText: "请输入新密码",
          contentPadding: const EdgeInsets.only(left: 10),
          filled: true,
          fillColor: mainColorPurple,
        ),
        gap: 10,
      ),
      InputProps.password(
        label: "再次输入新密码",
        isRequired: true,
        labelStyle: TextStyle(fontSize: 18),
        decoration: InputDecoration(
          hintText: "请再次输入新密码",
          contentPadding: const EdgeInsets.only(left: 10),
          filled: true,
          fillColor: mainColorPurple,
        ),
        isLast: true,
        validator: (v) {
          if (_controllers.asTextMap['newPassword'] != v) {
            return "两次输入密码不一致";
          }
          return null;
        },
      ),
    ].generateAndAssignController(_controllers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("更改密码", style: titleTextStyle),
        centerTitle: true,
        bottom: bottomLine,
      ),
      body: SafeArea(
        top: false,
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
          child: Column(
            children: [
              const Padding(padding: EdgeInsetsGeometry.only(top: 5)),
              Form(
                key: _formKey,
                child: Column(children: [..._inputs]),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: bgColorLight60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            side: BorderSide(color: mainColorPurple, width: 2.0),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            showMessageDialog(context, _message);
            final result = await _toChangePassword();
            if (context.mounted) {
              Navigator.pop(context);
            }
            if (result) {
              Navigator.pop(context);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '提交',
                style: TextStyle(
                  color: mainColorPurple,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _toChangePassword() async {
    _message.value = "正在发送更改密码请求";
    return sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return await ApiAuth.changePassword(_controllers.asTextMap);
      }),
      initMessageList: [],
      messageList: ["更改密码中.", "更改密码中..", "更改密码中..."],
      successMessage: "密码更改成功",
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controllers.disposeAll();
    _message.dispose();
  }
}
