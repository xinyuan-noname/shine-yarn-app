import 'package:flutter/material.dart';
import 'package:shine/components/input.dart';
import 'package:shine/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
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
        gap:5
      ),
      InputProps.cnName(
        label: "姓名",
        name: "username",
        color: mainColorPurple,
        isRequired: true,
        gap:5
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
                child: Column(
                  children: [
                    ..._inputs
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // 验证通过！可以提交数据
                        print(_formKey.toString());
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

  @override
  void dispose() {
    super.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
  }
}
