import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/pick_image.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/auth.dart';
import 'package:shine/services/profiles.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _avatarPath;
  final _logoutMessage = ValueNotifier("正在发送登出请求");
  final _avatarUploadMessage = ValueNotifier("正在上传头像文件");
  @override
  void initState() {
    super.initState();
    Future(() async {
      _avatarPath = await ProfileStorage.getAvatarPath();
      setState(() {});
    });
  }

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
        child: Container(
          alignment: Alignment.center,
          child: Column(
            children: [
              Padding(padding: EdgeInsetsGeometry.only(top: 5)),
              Stack(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Center(
                      child: _avatarPath != null
                          ? CircleAvatar(
                              backgroundColor: Colors.transparent,
                              radius: 50,
                              backgroundImage: FileImage(File(_avatarPath!)),
                            )
                          : defaultAvatar50,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _onUpload,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            _logoutMessage.value = "正在发送登出请求";
            showMessageDialog(context, _logoutMessage);
            final success = await _toLogout();
            if (context.mounted) {
              Navigator.pop(context);
            }
            if (success) {
              globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                "/login",
                clearOldRouter,
              );
            }
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

  Future _toUpload(bytes) async {
    final result = await Future.any([
      Future(() async {
        return await ApiProfiles.uploadAvatar(bytes);
      }),
      Future(() async {
        const duration = 500;
        while (true) {
          _logoutMessage.value = "正在上传中.";
          await Future.delayed(Duration(milliseconds: duration));
          _logoutMessage.value = "正在上传中..";
          await Future.delayed(Duration(milliseconds: duration));
          _logoutMessage.value = "正在上传中...";
          await Future.delayed(Duration(milliseconds: duration));
        }
      }),
    ]);
    if (result == false) {
      _logoutMessage.value = "上传失败";
      await Future.delayed(Duration(milliseconds: 500));
      return false;
    } else if (result == true) {
      _logoutMessage.value = "上传成功";
      await Future.delayed(Duration(milliseconds: 300));
      return true;
    }
    return;
  }

  _onUpload() {
    pickImage(context, (XFile image) async {
      _avatarUploadMessage.value = "正在上传头像文件";
      showMessageDialog(context, _avatarUploadMessage);
      Uint8List? imageData = await cropAvatar(image);
      if (imageData == null) {
        _avatarUploadMessage.value = "没有检测文件数据";
        Future(() {
          Navigator.pop(context);
        });
        return;
      }
      final success = await _toUpload(image);
      if (context.mounted) {
        Navigator.pop(context);
      }
      if (success) {
        await ProfileStorage.saveAvatar(imageData);
        _avatarPath = await ProfileStorage.getAvatarPath();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _logoutMessage.dispose();
    _avatarUploadMessage.dispose();
  }
}
