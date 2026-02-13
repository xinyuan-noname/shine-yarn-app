import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/auth.dart';
import 'package:shine/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _avatarPath;
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
            await ApiAuth.logout();
            globalNavigatorKey.currentState?.pushNamedAndRemoveUntil("/login",clearOldRouter);
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
                  fontWeight: FontWeight.w100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
