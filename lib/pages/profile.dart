import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/auth.dart';
import 'package:shine/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _avatarPath;
  final _logoutMessage = ValueNotifier("正在发送登出请求");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("我", style: titleTextStyle),
        centerTitle: true,
        bottom: bottomLine,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(padding: EdgeInsetsGeometry.only(top: 5)),
            _avatarPath != null
                ? CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: 50,
                    backgroundImage: FileImage(File(_avatarPath!)),
                  )
                : defaultAvatar50,
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: bgColorLight60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            side: BorderSide(color: Colors.red, width: 1.0),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          onPressed: () async {
            if (!ApiService.isOk) return;
            _toLogout().then((success) {
              if (context.mounted) {
                Navigator.pop(context);
              }
              if (success) {
                globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  "/login",
                  clearOldRouter,
                );
              }
            });
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => ValueListenableBuilder<String>(
                valueListenable: _logoutMessage,
                builder: (_, text, __) => Dialog(
                  child: Container(
                    height: 64,
                    alignment: Alignment.center,
                    child: Text(text),
                  ),
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 20, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                '退出登录',
                style: TextStyle(
                  color: Colors.redAccent,
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

  Future _toLogout() async {
    _logoutMessage.value = "正在发送登出请求";
    final result = await Future.wait([
      Future(() async {
        return await ApiAuth.logout();
      }),
      Future(() async {
        const duration = 800;
        await Future.delayed(Duration(milliseconds: duration));
        _logoutMessage.value = "正在吊销访问令牌";
        await Future.delayed(Duration(milliseconds: duration));
        _logoutMessage.value = "正在吊销刷新令牌";
        return true;
      }),
    ]);
    if (result[0] == false) {
      _logoutMessage.value = "登出失败";
      await Future.delayed(Duration(milliseconds: 500));
      return false;
    } else if (result[0] == true) {
      _logoutMessage.value = "登出成功";
      await Future.delayed(Duration(milliseconds: 300));
      return true;
    }
    return;
  }

  @override
  void dispose() {
    super.dispose();
    _logoutMessage.dispose();
  }
}
