import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/profiles.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _avatarPath;
  String _username = "???";
  String _id = "??????????";
  @override
  void initState() {
    Future(() async {
      _username = await ProfileStorage.getName();
      _avatarPath = await ProfileStorage.getAvatarPath();
      _id = await ProfileStorage.getId();
      setState(() {});
    });
    super.initState();
  }

  Future<void> _fetchData() async {
    final avatarData = await ApiProfiles.getAvatar(_id);
    await ProfileStorage.saveAvatar(avatarData);
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
                GestureDetector(
                  onTap: () async {
                    if (context.mounted) {
                      await globalNavigatorKey.currentState?.pushNamed(
                        '/profile',
                      );
                      await _update();
                    }
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username,
                      style: TextStyle(
                        letterSpacing: 1.0,
                        fontFamily: "SmileySans",
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      _id,
                      style: TextStyle(
                        fontFamily: "SmileySans",
                        color: Colors.grey,
                        fontWeight: FontWeight.w300,
                        fontSize: 12
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
      body: SafeArea(
        child: RefreshIndicator(
          color: mainColorPurple90,
          backgroundColor: bgColorLight,
          child: ListView.builder(
            itemCount: 1, 
            itemBuilder: (context, index) {
              return ListTile(title: Text('Item $index'));
            },
          ),
          onRefresh: () async {
            await _fetchData();
            await _update();
            await Future.delayed(Duration(seconds: 1));
          },
        ),
      ),
    );
  }
}
