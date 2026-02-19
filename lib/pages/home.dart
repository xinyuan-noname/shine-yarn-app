import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/storage/profile_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _avatarPath;
  String _username = "???";
  @override
  void initState() {
    Future(() async {
      _username = await ProfileStorage.getName();
      _avatarPath = await ProfileStorage.getAvatarPath();
      setState(() {});
    });
    super.initState();
  }

  Future<void> _update() async {
    _avatarPath = await ProfileStorage.getAvatarPath();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () async {
                    await Navigator.pushNamed(context, '/profile');
                    await _update();
                  },
                  child: _avatarPath != null
                      ? CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: 25,
                          backgroundImage: FileImage(File(_avatarPath!)),
                        )
                      : defaultAvatar25,
                ),
                SizedBox(width: 5),
                Column(
                  children: [
                    Text(
                      _username,
                      style: TextStyle(
                        letterSpacing: 1.0,
                        fontFamily: "SmileySans",
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        bottom: bottomLine,
      ),
    );
  }
}
