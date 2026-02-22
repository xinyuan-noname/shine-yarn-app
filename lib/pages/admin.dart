import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
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
  List<Map> _userInfoList = [];
  final ValueNotifier<String> _checkSignatureMessage = ValueNotifier("");
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
      title: Text("私钥文件异常"),
      content: Text("请立即上传"),
      onPress: () async {
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
    final result = await ApiAdmin.getUserInfo();
    if (result == null) return;
    print(result);
    _userInfoList = result;
    _listCount = result.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("管理界面", style: titleTextStyle),
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
                    return ListTile(title: Text('Item $index'));
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
}
