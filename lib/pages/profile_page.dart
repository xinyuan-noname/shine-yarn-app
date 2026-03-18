import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/pick_image.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_auth.dart';
import 'package:shine/services/api_profiles.dart';
import 'package:shine/services/ws.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/storage/token_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/device_info.dart';
import 'package:shine/utils/image.dart';
import 'package:shine/utils/routes_utils.dart';
import 'package:shine/utils/server.dart';
import 'package:shine/worker/worker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = "???";
  String? _gender;
  String _id = "??????????";
  bool _isPaswRequired = false;
  String _version = "?";
  int _tapVersionCount = 0;
  int _ts = 0;
  final _message = ValueNotifier("");
  @override
  void initState() {
    super.initState();
    Future(() async {
      await _refreshMyProfile();
    });
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Center(
            child: NetworkAvatar(id: _id, ts: _ts, radius: 50),
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
    );
  }

  Widget _buildName() {
    return Ink(
      color: Colors.white,
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: bodyPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("姓名", style: profileKeyTextStyle),
              Text(_username, style: profileValueTextStyle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGender() {
    return Ink(
      color: Colors.white,
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: bodyPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("性别", style: profileKeyTextStyle),
              Text(
                _gender == "male"
                    ? "男"
                    : _gender == "female"
                    ? "女"
                    : "无可奉告",
                style: profileValueTextStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildId() {
    return Ink(
      color: Colors.white,
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: bodyPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("学号", style: profileKeyTextStyle),
              Text(_id, style: profileValueTextStyle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassword() {
    return Ink(
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          await Future.delayed(Duration(milliseconds: 225));
          if (context.mounted) {
            globalNavigatorKey.currentState?.pushNamed("/password");
          }
        },
        child: Container(
          padding: bodyPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
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
    );
  }

  Widget _buildPasswordRequired() {
    return Ink(
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.check_circle_rounded,
                        color: mainColorGreenBlue,
                      ),
                      title: Text('强制密码登录'),
                      onTap: () async {
                        await ApiAuth.changePasswordRequired({
                          "passwordRequired": 1,
                        });
                        _isPaswRequired = true;
                        await ProfileStorage.savePasswordRequired(true);
                        Navigator.of(context).pop();
                        if (ApiService.userType == "guest") {
                          await Future.wait([
                            showToast(msg: "检测到处于游客状态，正在跳转至登录页"),
                            TokenStorage.deleteAccessToken(),
                            TokenStorage.deleteRefreshToken(),
                          ]);
                          globalNavigatorKey.currentState
                              ?.pushNamedAndRemoveUntil(
                                "/login",
                                clearOldRouter,
                              );
                        }
                        setState(() {});
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.error, color: mainColorRed),
                      title: Text('可无密码登录'),
                      onTap: () async {
                        await ApiAuth.changePasswordRequired({
                          "passwordRequired": 0,
                        });
                        _isPaswRequired = false;
                        await ProfileStorage.savePasswordRequired(false);
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Container(
          padding: bodyPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("强制密码登录", style: profileKeyTextStyle),
              Row(
                children: [
                  Text(
                    _isPaswRequired ? "是" : "否",
                    style: profileValueTextStyle,
                  ),
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
    );
  }

  Widget _buildVersion() {
    return Ink(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          _tapVersionCount++;
          if (_tapVersionCount >= 5) {
            gotoAdminDialog(context);
            _tapVersionCount = 0;
          }
        },
        child: Container(
          padding: bodyPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("版本号", style: profileKeyTextStyle),
              Text(_version, style: profileValueTextStyle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrame() {
    return Ink(
      color: Colors.white,
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: bodyPadding,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("应用框架", style: profileKeyTextStyle),
              Text("Flutter&Express.js", style: profileValueTextStyle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloper() {
    return Ink(
      color: Colors.white,
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: bodyPadding,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("开发设计", style: profileKeyTextStyle),
              Text("Shine Yarn", style: profileValueTextStyle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTitle(String txt) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20, bottom: 5),
      child: Text(txt, style: TextStyle(color: Colors.grey, fontSize: 16)),
    );
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
        child: RefreshIndicator(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(top: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  _buildAvatar(),
                  SizedBox(height: 20),
                  _buildListTitle("用户"),
                  _buildName(),
                  bottomLineSmall,
                  _buildGender(),
                  bottomLineSmall,
                  _buildId(),
                  bottomLineSmall,
                  _buildPassword(),
                  bottomLineSmall,
                  _buildPasswordRequired(),
                  const SizedBox(height: 5),
                  _buildListTitle("应用"),
                  _buildVersion(),
                  bottomLineSmall,
                  _buildFrame(),
                  bottomLineSmall,
                  _buildDeveloper(),
                  const SizedBox(height: 35),
                ],
              ),
            ),
          ),
          onRefresh: () async {
            await _fetchMyProfile();
            await _refreshMyProfile();
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: bgColorLight60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            side: BorderSide(color: mainColorRed, width: 2.0),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          onPressed: () async {
            await _toLogout();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 24, color: mainColorRed),
              SizedBox(width: 10),
              Text(
                '退出登录',
                style: TextStyle(
                  color: mainColorRed,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _refreshMyProfile() async {
    _username = await ProfileStorage.getName();
    _gender = await ProfileStorage.getGender();
    _id = await ProfileStorage.getId();
    _isPaswRequired = await ProfileStorage.getPasswordRequired();
    _ts = await ProfileStorage.getAvatarTs();
    _version = await getVersionInfo();
    setState(() {});
  }

  Future _fetchMyProfile() async {
    await Worker.syncMyData();
  }

  Future _toLogout() async {
    _message.value = "正在发送登出请求";
    showMessageDialog(context, _message);
    await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return await ApiAuth.logout();
      }),
      initMessageList: [],
      messageList: ['正在吊销令牌.', '正在吊销令牌..', '正在吊销令牌...'],
      successMessage: '登出成功',
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    WebSocketServer.dispose();
    Worker.dispose();
    globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      "/login",
      clearOldRouter,
    );
  }

  Future _toUpload(Uint8List bytes) async {
    return await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return await ApiProfiles.uploadAvatar(bytes);
      }),
      initMessageList: [],
      messageList: ["正在上传中.", "正在上传中..", "正在上传中..."],
      successMessage: "上传成功",
    );
  }

  _onUpload() {
    pickImage(context, (XFile image) async {
      _message.value = "正在上传头像文件";
      showMessageDialog(context, _message);
      Uint8List? imageData = await cropAvatar(image);
      if (imageData == null) {
        _message.value = "没有检测文件数据";
        Future(() {
          Navigator.of(context).pop();
        });
        return;
      }
      final success = await _toUpload(imageData);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      if (success) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        await ProfileStorage.saveAvatarTs(ts);
        _ts = ts;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _message.dispose();
  }
}
