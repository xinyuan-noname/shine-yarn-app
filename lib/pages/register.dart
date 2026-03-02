import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/input.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/radio.dart';
import 'package:shine/services/api_admin.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/server.dart';

const labelStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 16,
  fontWeight: FontWeight.w500,
);
const hintStyle = TextStyle(fontFamily: "SmileySans", color: bgColorLight60);
const inputStyle = TextStyle(fontFamily: "SmileySans", color: bgColorLight);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<String> _message = ValueNotifier("正在发送注册请求");
  late final List<Input> _inputs;
  final map = <String, dynamic>{};
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
        gap: 5,
        onSavedMap: map,
      ),
      InputProps.cnName(
        label: "姓名",
        name: "username",
        labelStyle: labelStyle,
        hintStyle: hintStyle,
        inputStyle: inputStyle,
        color: mainColorPurple90,
        isRequired: true,
        gap: 5,
        onSavedMap: map,
      ),
      InputProps.password(
        hintStyle: hintStyle,
        color: mainColorPurple90,
        labelStyle: labelStyle,
        inputStyle: inputStyle,
        onSavedMap: map,
      ),
    ].generate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("注册用户", style: titleTextStyle),
        centerTitle: true,
        bottom: bottomLine,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    ..._inputs,
                    Radios.gender(
                      labelStyle: labelStyle,
                      inputStyle: inputStyle,
                      color: mainColorPurple,
                      gap: 5,
                      onSavedMap: map,
                    ),
                    Radios.comfirm(
                      label: "是否为管理员",
                      name: 'isAdmin',
                      labelStyle: labelStyle,
                      inputStyle: inputStyle,
                      color: mainColorPurple,
                      gap: 5,
                      onSavedMap: map,
                      initialValue: false
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: bgColorLight60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            side: BorderSide(color: mainColorPurple80, width: 2.0),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          onPressed: () async {
            if (_formKey.currentState == null) return;
            if (!_formKey.currentState!.validate()) return;
            _formKey.currentState?.save();
            final success = await _toRegister();
            if (context.mounted) {
              Navigator.pop(context);
            }
            if (success) {
              Navigator.pop(context);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.app_registration_sharp,
                size: 20,
                color: darkColorPurple,
              ),
              SizedBox(width: 10),
              Text(
                '提交注册',
                style: TextStyle(
                  color: darkColorPurple,
                  fontSize: 20,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _toRegister() async {
    _message.value = "正在发送登出请求";
    showMessageDialog(context, _message);
    return await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return await ApiAdmin.register(map);
      }),
      initMessageList: [],
      messageList: ["正在注册中.", "正在注册中..", "正在注册中..."],
      successMessage: "注册成功",
      successMessageDuration: Duration(milliseconds: 300),
      failMessageDuration: Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _message.dispose();
  }
}
