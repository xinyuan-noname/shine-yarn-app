import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/user_info_card.dart';
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
  int _listCount = 0;
  List _userInfoList = [];
  final ValueNotifier<String> _checkSignatureMessage = ValueNotifier("");
  final List<ValueNotifier<String>> _issuePasswordKeyMessageList = [];
  final List<ValueNotifier<String>> _deleteUserMessageList = [];
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
          showMessageDialog(context, _checkSignatureMessage);
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
      _checkSignatureMessage,
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

  Future _getUserInfo() async {
    for (final m in _issuePasswordKeyMessageList) {
      m.dispose();
    }
    final result = await ApiAdmin.getUserInfo();
    print(result);
    if (result == null) return;
    _userInfoList = result;
    _listCount = result.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("管理界面", style: titleTextStyle),
        actions: [
          IconButton(icon: Icon(Icons.add, size: 32), onPressed: () {}),
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
                  itemCount: max(_listCount, 1),
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    if (_listCount == 0) {
                      return Container(
                        alignment: Alignment.center,
                        child: Text(
                          "暂无用户数据",
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      );
                    }
                    final userInfo = _userInfoList[index];
                    final issuePasswordKeyMessage = ValueNotifier("");
                    _issuePasswordKeyMessageList.add(issuePasswordKeyMessage);
                    final deleteUserMessage = ValueNotifier("");
                    _deleteUserMessageList.add(deleteUserMessage);
                    final id = userInfo["id"];
                    return UserInfoCard(
                      userInfo: userInfo,
                      onDelete: () {},
                      onEdit: () async {
                        await _deleteUser(
                          deleteUserMessage: deleteUserMessage,
                          id: id,
                        );
                      },
                      onIssuePswdKey: () async {
                        await _issuePasswordKey(
                          issuePasswordKeyMessage: issuePasswordKeyMessage,
                          id: id,
                        );
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

  Future<void> _deleteUser({
    required ValueNotifier<String> deleteUserMessage,
    required String id,
  }) async {
    showMessageDialog(context, deleteUserMessage);
    final success = await sendRequestAndChangeMessage(
      deleteUserMessage,
      request: Future(() async {
        return await ApiAdmin.issuePasswordKey(id);
      }),
      initMessageList: [],
      messageList: ["正在为$id签发密码令牌.", "正在为$id签发密码令牌..", "正在为$id签发密码令牌..."],
      successMessage: "签发成功",
    );
    if (context.mounted) {
      Navigator.pop(context);
    }
    if (success) {
      _getUserInfo();
      setState(() {});
    }
  }

  Future<void> _issuePasswordKey({
    required ValueNotifier<String> issuePasswordKeyMessage,
    required String id,
  }) async {
    late String passwordKey;
    showMessageDialog(context, issuePasswordKeyMessage);
    final success = await sendRequestAndChangeMessage(
      issuePasswordKeyMessage,
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

  _disposeAllUserMessage() {
    for (final m in _issuePasswordKeyMessageList) {
      m.dispose();
    }
    _issuePasswordKeyMessageList.clear();
    for (final m in _deleteUserMessageList) {
      m.dispose();
    }
    _deleteUserMessageList.clear();
  }

  @override
  void dispose() {
    super.dispose();
    _checkSignatureMessage.dispose();
    _disposeAllUserMessage();
  }
}
