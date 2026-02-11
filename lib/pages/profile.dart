import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/line.dart';
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
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          onPressed: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text('退出登录')],
          ),
        ),
      ),
    );
  }
}
