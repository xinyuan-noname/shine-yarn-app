import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/storage/admin_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/file.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  void initState() {
    super.initState();
    _uploadSignature();
  }

  Future<void> _uploadSignature() async {
    showAlertDialog(
      context: context,
      title: Text("未检测到私钥文件"),
      content: Text("请立即选取"),
      onPress: () async {
        final file = await pickFile();
        if (file == null || file.bytes == null) {
          Navigator.pop(context);
          showAlertDialog(
            context: context,
            title: Text("选中的私钥文件异常"),
            content: Text("请重新操作"),
            onPress: () {
              _uploadSignature();
            },
          );
          return;
        }
        await AdminStorage.saveSignature(
          data: file.bytes!,
          filename: file.name,
        );
      },
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
