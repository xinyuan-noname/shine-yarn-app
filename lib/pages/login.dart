import 'package:flutter/material.dart';
import 'package:shine/components/input.dart';
import 'package:shine/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              child: const Text("学号姓名密码登录", style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 40),
            NumberInput(title: "学号", color: mainColorPurple, isRequired: true),
            const SizedBox(height: 10),
            CnNameInput(color: mainColorPurple, isRequired: true),
            const SizedBox(height: 10),
            Password(color: mainColorPurple),
            const SizedBox(height: 30),
            Container(
              color: mainColorPurple,
              width: double.infinity,
              height: 48,
              child: TextButton(onPressed: () {}, child: const Text("登录")),
            ),
          ],
        ),
      ),
    );
  }
}
