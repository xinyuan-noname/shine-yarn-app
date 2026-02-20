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
  final ValueNotifier<String> _checkSignatureMessage = ValueNotifier("");
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _uploadSignature();
    });
  }

  Future<void> _uploadSignature() async {
    showAlertDialog(
      context: context,
      title: Text("未检测到私钥文件"),
      content: Text("请立即选取"),
      onPress: () async {
        if (context.mounted) {
          Navigator.pop(context);
        }
        bool success = false;
        while (!success) {
          PlatformFile? file = await pickFile();
          if (file == null || file.bytes == null) {
            showAlertDialog(
              context: context,
              title: Text("选中的私钥文件异常"),
              content: Text("请重新操作"),
              onPress: () async {
                file = await pickFile();
                if (file != null && file?.bytes != null) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            );
            return;
          }
          await AdminStorage.saveSignature(
            data: file.bytes!,
            filename: file.name,
          );
          showMessageDialog(context, _checkSignatureMessage);
          success = await _checkSignature();
          if (context.mounted) {
            Navigator.pop(context);
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
      }),
      initMessageList: [],
      messageList: ["正在校验签名.", "正在校验签名..", "正在校验签名..."],
      successMessage: "签名校验成功",
    );
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
            await Future.delayed(Duration(seconds: 1));
          },
        ),
      ),
    );
  }
}
