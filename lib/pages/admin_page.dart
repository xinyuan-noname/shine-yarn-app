import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/icon_button.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/user_info_card.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api_admin.dart';
import 'package:shine/storage/admin_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/share.dart';
import 'package:shine/utils/file.dart';
import 'package:shine/utils/server.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isOk = false;
  bool _batchMode = false;
  List _userInfoList = [];
  final List<int> _selectedIndexList = [];
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
          Navigator.of(context).pop();
        }
        bool success = false;
        while (!success) {
          PlatformFile? file = await pickFile(exts: ["pem"]);
          await AdminStorage.saveSignature(file!.bytes!);
          showMessageDialog(context, _message);
          success = await _checkSignature();
          if (context.mounted) {
            Navigator.of(context).pop();
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
    if (result == null) {
      await ApiAdmin.getUserInfo();
      return;
    }
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
                              Navigator.of(context).pop();
                              await globalNavigatorKey.currentState?.pushNamed(
                                "/register",
                              );
                              await _getUserInfo();
                              setState(() {});
                            }
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.group_add_outlined),
                          title: Text(
                            '通过excel创建用户',
                            style: bottomListTitleTextStyle,
                          ),
                          onTap: () async {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              _registerFromExcel();
                              await _getUserInfo();
                              setState(() {});
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
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_batchMode)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 1,
                            style: BorderStyle.solid,
                            color: const Color.fromRGBO(158, 158, 158, 0.8),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SelectAllButton(
                            selectedIndexList: _selectedIndexList,
                            allItemList: _userInfoList,
                            callback: () {
                              setState(() {});
                            },
                            unselectedColor: Colors.grey,
                            selectedColor: mainColorGreenBule,
                          ),
                          IconButton(
                            onPressed: () {
                              _batchMode = false;
                              _selectedIndexList.clear();
                              setState(() {});
                            },
                            icon: Icon(Icons.close, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      color: mainColorPurple90,
                      backgroundColor: bgColorLight,
                      child: _buildViewList(),
                      onRefresh: () async {
                        await _getUserInfo();
                        setState(() {});
                      },
                    ),
                  ),
                ],
              )
            : Container(
                alignment: Alignment.center,
                child: Icon(Icons.lock, size: 72, color: Colors.grey),
              ),
      ),
      bottomNavigationBar: _batchMode
          ? BottomAppBar(
              color: bgColorLight60,
              height: 50,
              padding: EdgeInsets.zero,
              notchMargin: 0,
              shadowColor: Colors.white,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _deleteUserBatch,
                      icon: Icon(Icons.delete),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildViewList() {
    return ListView.builder(
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
        final isAdmin = userInfo['userType'] == "admin";
        final userInfoCard = UserInfoCard(
          userInfo: userInfo,
          onDelete: _batchMode
              ? null
              : () async {
                  final result = await showConfrimDialog(
                    context: context,
                    title: "确认删除$id($username)吗？",
                    content: "此操作无法撤回！",
                  );
                  if (result) {
                    await _deleteUser(id);
                    await _getUserInfo();
                    setState(() {});
                  }
                },
          onEdit: _batchMode
              ? null
              : () async {
                  await showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: Icon(Icons.manage_accounts_outlined),
                              title: Text(
                                isAdmin ? '撤销$id管理员权限' : '授予$id管理员权限',
                                style: bottomListTitleTextStyle,
                              ),
                              onTap: () async {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                                await _changeAdmin(id, isAdmin ? 0 : 1);
                                await _getUserInfo();
                                setState(() {});
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.star),
                              title: Text(
                                "设置职务",
                                style: bottomListTitleTextStyle,
                              ),
                              onTap: () async {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                                final position = await showPromptDialog(
                                  context: context,
                                  title: "设置职位",
                                  label: "职务",
                                );
                                if (position == null) return;
                                await _changePosition(id, position);
                                await _getUserInfo();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
          onIssuePswdKey: _batchMode
              ? null
              : () {
                  _issuePasswordKey(id);
                },
          onLongPress: () {
            _batchMode = true;
            _selectedIndexList.add(index);
            setState(() {});
          },
          onPress: _batchMode
              ? () {
                  if (_selectedIndexList.contains(index)) {
                    _selectedIndexList.remove(index);
                  } else {
                    _selectedIndexList.add(index);
                  }
                  setState(() {});
                }
              : null,
        );
        return _batchMode
            ? Row(
                children: [
                  if (_selectedIndexList.contains(index))
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: mainColorGreenBule,
                      size: 50,
                      weight: 10,
                    ),
                  Expanded(child: userInfoCard),
                ],
              )
            : userInfoCard;
      },
    );
  }

  Future<void> _registerFromExcel() async {
    PlatformFile? file = await pickFile(exts: ["xlsx", "xls"]);
    if (file == null || file.bytes == null) return;
    _message.value = "";
    final List<String> errorResultList = [];
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        final result = await ApiAdmin.registerFromExcel(file.bytes!);
        if (result is String) return result;
        if (result is List) {
          for (final map in result) {
            if (map is! Map) continue;
            if (map["success"] == false && map["id"] is String) {
              errorResultList.add(
                "${map["id"]}注册出错, 出错原因:${map["error"] ?? "未知"}",
              );
            }
          }
          return null;
        }
        return "注册出错";
      }),
      initMessageList: [],
      messageList: ["正在进行注册中.", "正在进行注册中..", "正在进行注册中..."],
      successMessage: "收到注册信息",
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    if (success) {
      _getUserInfo().then((_) {
        setState(() {});
      });
      for (final errorResult in errorResultList) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorResult)));
      }
    }
  }

  Future<void> _changeAdmin(String id, int isAdmin) async {
    _message.value = "";
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return await ApiAdmin.changeAdminStatus(id: id, isAdmin: isAdmin);
      }),
      initMessageList: [],
      messageList: ["正在更改$id的权限.", "正在更改$id的权限..", "正在更改$id的权限..."],
      successMessage: "更改成功",
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    if (success) {
      await _getUserInfo();
      setState(() {});
    }
  }

  Future<void> _changePosition(String id, String position) async {
    _message.value = "";
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return await ApiAdmin.changePosition(id: id, position: position);
      }),
      initMessageList: [],
      messageList: ["正在更改$id的身份.", "正在更改$id的身份..", "正在更改$id的身份..."],
      successMessage: "更改成功",
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    if (success) {
      await _getUserInfo();
      setState(() {});
    }
  }

  Future<void> _deleteUser(String id) async {
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
      Navigator.of(context).pop();
    }
    if (success) {
      await _getUserInfo();
      setState(() {});
    }
  }

  Future<void> _deleteUserBatch() async {
    _message.value = "";
    showMessageDialog(context, _message);
    final deleteUserList = List.generate(_selectedIndexList.length, (index) {
      return {"id": _userInfoList[index]["id"]};
    });
    final List<String> errorResultList = [];
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        final result = await ApiAdmin.deleteUserBatch(deleteUserList);
        if (result is String) return result;
        if (result is List) {
          for (final map in result) {
            if (map is! Map) continue;
            if (map["success"] == false && map["id"] is String) {
              errorResultList.add(
                "${map["id"]}注册出错, 出错原因:${map["error"] ?? "未知"}",
              );
            }
          }
          return null;
        }
        return "删除失败";
      }),
      initMessageList: [],
      messageList: ["正在删除用户.", "正在删除用户..", "正在删除用户..."],
      successMessage: "删除成功",
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    if (success) {
      _batchMode = false;
      _selectedIndexList.clear();
      setState(() {});
      await _getUserInfo();
      setState(() {});
      for (final errorResult in errorResultList) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorResult)));
      }
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
      Navigator.of(context).pop();
    }
    if (success) {
      await sharePswdKey(id: id, passwordKey: passwordKey);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _message.dispose();
  }
}
