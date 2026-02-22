import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/user_info_card.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/admin.dart';
import 'package:shine/storage/admin_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/file.dart';
import 'package:shine/utils/server.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isOk = false;
  List _userInfoList = [];
  final ValueNotifier<String> _message = ValueNotifier("");
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _uploadSignature();
    });
  }

  Future<void> _uploadSignature() async {
    showAlertDialog(
      context: context,
      title: "私钥文件异常",
      content: "请立即上传",
      onYes: () async {
        if (context.mounted) {
          Navigator.pop(context);
        }
        bool success = false;
        while (!success) {
          PlatformFile? file = await pickFile();
          await AdminStorage.saveSignature(file!.bytes!);
          showMessageDialog(context, _message);
          success = await _checkSignature();
          if (context.mounted) {
            Navigator.pop(context);
            _isOk = success;
            await _getUserInfo();
            setState(() {});
          }
        }
      },
    );
  }

  Future<bool> _checkSignature() async {
    return sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        final signature = await AdminStorage.getSignature();
        if (signature != null) {
          ApiAdmin.setRSASignature(signature);
          return await ApiAdmin.checkSignatureByRSA();
        }
        return null;
      }),
      initMessageList: [],
      messageList: ["正在校验签名.", "正在校验签名..", "正在校验签名..."],
      successMessage: "签名校验成功",
    );
  }

  Future<void> _getUserInfo() async {
    final result = await ApiAdmin.getUserInfo();
    print(result);
    if (result == null) return;
    _userInfoList = result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("管理界面", style: titleTextStyle),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: 32),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: Icon(Icons.person_2_outlined),
                          title: Text('创建新用户', style: bottomListTitleTextStyle),
                          onTap: () async {
                            if (context.mounted) {
                              Navigator.pop(context);
                              globalNavigatorKey.currentState?.pushNamed(
                                "/register",
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
        centerTitle: true,
        bottom: bottomLine,
      ),
      body: SafeArea(
        child: _isOk
            ? RefreshIndicator(
                color: mainColorPurple90,
                backgroundColor: bgColorLight,
                child: ListView.builder(
                  itemCount: max(_userInfoList.length, 1),
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    if (_userInfoList.isEmpty) {
                      return Container(
                        alignment: Alignment.center,
                        child: Text(
                          "暂无用户数据",
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      );
                    }
                    final userInfo = _userInfoList[index];
                    final id = userInfo["id"];
                    final username = userInfo["username"];
                    return UserInfoCard(
                      userInfo: userInfo,
                      onDelete: () {
                        showConfrimDialog(
                          context: context,
                          title: "确认删除$id($username)吗？",
                          content: "此操作无法撤回！",
                          onYes: () {
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                            _deleteUser(id);
                          },
                        );
                      },
                      onEdit: () {},
                      onIssuePswdKey: () {
                        _issuePasswordKey(id);
                      },
                    );
                  },
                ),
                onRefresh: () async {
                  await _getUserInfo();
                  setState(() {});
                },
              )
            : Container(
                alignment: Alignment.center,
                child: Icon(Icons.lock, size: 72, color: Colors.grey),
              ),
      ),
    );
  }

  Future<void> _deleteUser(id) async {
    _message.value = "";
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return await ApiAdmin.deleteUser(id);
      }),
      initMessageList: [],
      messageList: ["正在删除用户$id.", "正在删除用户$id..", "正在删除用户$id..."],
      successMessage: "删除成功",
    );
    if (context.mounted) {
      Navigator.pop(context);
    }
    if (success) {
      _getUserInfo();
      setState(() {});
    }
  }

  Future<void> _issuePasswordKey(id) async {
    _message.value = "";
    late String passwordKey;
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        final result = await ApiAdmin.issuePasswordKey(id);
        if (result is String) return result;
        if (result is Map && result["passwordKey"] is String) {
          passwordKey = result["passwordKey"];
          return null;
        }
        return "签发失败";
      }),
      initMessageList: [],
      messageList: ["正在为$id签发密码令牌.", "正在为$id签发密码令牌..", "正在为$id签发密码令牌..."],
      successMessage: "签发成功",
    );
    if (context.mounted) {
      Navigator.pop(context);
    }
    if (success) {
      await Clipboard.setData(ClipboardData(text: "$id的密码令牌: $passwordKey"));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("已经$id的密码令牌复制到剪切板中")));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("令牌为: $passwordKey")));
    }
  }

  @override
  void dispose() {
    super.dispose();
    _message.dispose();
  }
}
