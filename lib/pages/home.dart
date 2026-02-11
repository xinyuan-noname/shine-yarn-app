import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _avatarPath;
  late String _username;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: _avatarPath != null
                      ? CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: 68,
                          backgroundImage: FileImage(File(_avatarPath!)),
                        )
                      : defaultAvatar,
                ),
                Text(_username),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
