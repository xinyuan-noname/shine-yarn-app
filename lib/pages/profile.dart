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
import 'package:shine/utils/device_info.dart';
import 'package:shine/utils/image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _avatarPath;
  String _username = "???";
  String _gender = "?";
  String _id = "??????????";
  String _isPaswRequired = "否";
  String _version = "?";
  int _tapVersionCount = 0;
  final _logoutMessage = ValueNotifier("正在发送登出请求");
  final _avatarUploadMessage = ValueNotifier("正在上传头像文件");
  @override
  void initState() {
    super.initState();
    Future(() async {
      _avatarPath = await ProfileStorage.getAvatarPath();
      _username = await ProfileStorage.getName();
      _gender = await ProfileStorage.getGender();
      _id = await ProfileStorage.getId();
      _isPaswRequired = await ProfileStorage.getPasswordRequired();
      _version = await getVersionInfo();
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
              SizedBox(height: 20),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20, bottom: 5),
                child: const Text(
                  "用户",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              Ink(
                color: Colors.white,
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    padding: profilePadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("姓名", style: profileKeyTextStyle),
                        Text(_username, style: profileValueTextStyle),
                      ],
                    ),
                  ),
                ),
              ),
              bottomLineSmall,
              Ink(
                color: Colors.white,
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    padding: profilePadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("性别", style: profileKeyTextStyle),
                        Text(_gender, style: profileValueTextStyle),
                      ],
                    ),
                  ),
                ),
              ),
              bottomLineSmall,
              Ink(
                color: Colors.white,
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    padding: profilePadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("学号", style: profileKeyTextStyle),
                        Text(_id, style: profileValueTextStyle),
                      ],
                    ),
                  ),
                ),
              ),
              bottomLineSmall,
              Ink(
                color: Colors.white,
                child: InkWell(
                  onTap: () => {},
                  child: Container(
                    padding: profilePadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("更改密码", style: profileKeyTextStyle),
                        Icon(
                          Icons.chevron_right,
                          size: profileFontSize,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottomLineSmall,
              Ink(
                color: Colors.white,
                child: InkWell(
                  onTap: () => {},
                  child: Container(
                    padding: profilePadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("强制密码登录", style: profileKeyTextStyle),
                        Row(
                          children: [
                            Text(_isPaswRequired, style: profileValueTextStyle),
                            Icon(
                              Icons.chevron_right,
                              size: profileFontSize,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20, top: 5, bottom: 5),
                child: const Text(
                  "应用",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              Ink(
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    _tapVersionCount++;
                    if (_tapVersionCount >= 5) {
                      globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                        '/admin',
                        clearOldRouter,
                      );
                    }
                  },
                  child: Container(
                    padding: profilePadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("版本号", style: profileKeyTextStyle),
                        Text(_version, style: profileValueTextStyle),
                      ],
                    ),
                  ),
                ),
              ),
              Ink(
                color: Colors.white,
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    padding: profilePadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("应用框架", style: profileKeyTextStyle),
                        Text("Flutter&Express&SQLite3", style: profileValueTextStyle),
                      ],
                    ),
                  ),
                ),
              ),
              Ink(
                color: Colors.white,
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    padding: profilePadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("开发设计", style: profileKeyTextStyle),
                        Text("Shine Yarn", style: profileValueTextStyle),
                      ],
                    ),
                  ),
                ),
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
            await _toLogout();
            if (context.mounted) {
              Navigator.pop(context);
            }
            globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
              "/login",
              clearOldRouter,
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
    String? result;
    await Future.wait([
      Future(() async {
        result = await ApiAuth.logout();
      }),
      Future(() async {
        const duration = 200;
        await Future.delayed(Duration(milliseconds: duration));
        if (result != null) return null;
        _logoutMessage.value = "正在吊销访问令牌.";
        await Future.delayed(Duration(milliseconds: duration));
        if (result != null) return null;
        _logoutMessage.value = "正在吊销访问令牌..";
        await Future.delayed(Duration(milliseconds: duration));
        if (result != null) return null;
        _logoutMessage.value = "正在吊销访问令牌...";
        await Future.delayed(Duration(milliseconds: duration));
        if (result != null) return null;
        _logoutMessage.value = "正在吊销刷新令牌.";
        await Future.delayed(Duration(milliseconds: duration));
        if (result != null) return null;
        _logoutMessage.value = "正在吊销刷新令牌..";
        await Future.delayed(Duration(milliseconds: duration));
        if (result != null) return null;
        _logoutMessage.value = "正在吊销刷新令牌...";
      }),
    ]);
    if (result == null) {
      _logoutMessage.value = "登出成功";
      await Future.delayed(Duration(milliseconds: 300));
      return true;
    } else {
      _logoutMessage.value = result!;
      await Future.delayed(Duration(milliseconds: 500));
      return false;
    }
  }

  Future _toUpload(Uint8List bytes) async {
    bool animate = true;
    final result = await Future.any([
      Future(() async {
        return await ApiProfiles.uploadAvatar(bytes);
      }),
      Future(() async {
        const duration = 500;
        while (animate) {
          _avatarUploadMessage.value = "正在上传中.";
          await Future.delayed(Duration(milliseconds: duration));
          if (!animate) break;
          _avatarUploadMessage.value = "正在上传中..";
          await Future.delayed(Duration(milliseconds: duration));
          if (!animate) break;
          _avatarUploadMessage.value = "正在上传中...";
          await Future.delayed(Duration(milliseconds: duration));
        }
      }),
    ]);
    animate = false;
    if (result == null) {
      _avatarUploadMessage.value = "上传成功";
      await Future.delayed(Duration(milliseconds: 300));
      return true;
    } else {
      _avatarUploadMessage.value = result;
      await Future.delayed(Duration(milliseconds: 500));
      return false;
    }
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
      final success = await _toUpload(imageData);
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
