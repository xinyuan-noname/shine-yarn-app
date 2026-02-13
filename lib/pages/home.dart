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
  late String _username;
  @override
  void initState() async {
    _username = await ProfileStorage.getName() ?? "???";
    super.initState();
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
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
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
                    Text(_username, style: TextStyle(letterSpacing: 1.0)),
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
