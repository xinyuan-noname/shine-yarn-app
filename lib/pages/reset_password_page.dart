import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/input.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/user_info_card.dart';
import 'package:shine/extensions/text_editing.dart';
import 'package:shine/services/api_auth.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/server.dart';

const contentTextStyle = TextStyle(
  fontSize: 20,
  fontFamily: 'SmileySans',
  fontWeight: FontWeight.w500,
);
const contentStrongTextStyle = TextStyle(
  fontSize: 20,
  fontFamily: 'SmileySans',
  fontWeight: FontWeight.w600,
  fontStyle: FontStyle.italic,
  color: Colors.redAccent,
);

const double inputGap = 10;

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final List _userInfoList = [];
  String _errorMessage = "获取管理员列表数据中";
  bool _isChanging = false;
  final _controllers = <String, TextEditingController>{};
  final ValueNotifier<String> _message = ValueNotifier("正在发送重置密码请求");
  late final List<Input> _inputs;
  @override
  void initState() {
    super.initState();
    _initInputs();
    _getAdminList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _controllers["id"]?.text = args;
      }
    });
  }

  void _initInputs() {
    _inputs = [
      InputProps.number(
        label: "学号",
        name: "id",
        labelStyle: labelStyle,
        hintStyle: hintStyle,
        inputStyle: inputStyle,
        color: mainColorPurple90,
        isRequired: true,
        gap: inputGap,
      ),
      InputProps(
        label: "密码令牌",
        name: "passwordKey",
        labelStyle: labelStyle,
        hintStyle: hintStyle,
        inputStyle: inputStyle,
        color: mainColorPurple90,
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        isRequired: true,
        gap: inputGap,
      ),
      InputProps.password(
        label: "新密码",
        name: "newPassword",
        isRequired: true,
        labelStyle: labelStyle,
        inputStyle: inputStyle,
        decoration: InputDecoration(
          hintStyle: hintStyle,
          hintText: "请输入新密码",
          contentPadding: const EdgeInsets.only(left: 10),
          filled: true,
          fillColor: mainColorPurple,
        ),
        gap: inputGap,
      ),
      InputProps.password(
        label: "再次输入新密码",
        isRequired: true,
        labelStyle: labelStyle,
        inputStyle: inputStyle,
        decoration: InputDecoration(
          hintStyle: hintStyle,
          hintText: "请再次输入新密码",
          contentPadding: const EdgeInsets.only(left: 10),
          filled: true,
          fillColor: mainColorPurple,
        ),
        isLast: true,
        validator: (v) {
          if (_controllers.asTextMap['newPassword'] != v) {
            return "两次输入密码不一致";
          }
          return null;
        },
      ),
    ].generateAndAssignController(_controllers);
  }

  _getAdminList() async {
    final result = await ProfileStorage.getAdminList();
    if (result == null) {
      _fetchAdminList();
      return;
    }
    _userInfoList.addAll(result);
    setState(() {});
  }

  _fetchAdminList() async {
    bool stop = false;
    Future(() async {
      while (!stop) {
        _errorMessage = "获取管理员列表数据中.";
        await Future.delayed(Duration(milliseconds: 500));
        if (stop) return;
        _errorMessage = "获取管理员列表数据中..";
        await Future.delayed(Duration(milliseconds: 500));
        if (stop) return;
        _errorMessage = "获取管理员列表数据中...";
        await Future.delayed(Duration(milliseconds: 500));
        if (stop) return;
      }
    });
    final result = await ApiAuth.getAdminInfo();
    stop = true;
    if (result == null) return;
    if (result is String) {
      _errorMessage = result;
    }
    if (result is List) {
      _userInfoList.addAll(result);
      setState(() {});
      await ProfileStorage.saveAdminList(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("重置密码", style: titleTextStyle),
        centerTitle: true,
        bottom: bottomLine,
      ),
      body: _isChanging ? _buildSecondViewBody() : _buildFirstViewBody(),
      bottomSheet: _isChanging
          ? _buildSecondViewBottom()
          : _buildFirstViewBottom(),
    );
  }

  Widget _buildMainContent() {
    if (_userInfoList.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: Text(
          _errorMessage,
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      );
    }
    return CarouselSlider(
      items: _userInfoList.map((userInfo) {
        final userInfoCard = UserInfoCard(
          userInfo: userInfo,
          noOperation: true,
        );
        return userInfoCard;
      }).toList(),
      options: CarouselOptions(
        height: 160,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: Duration(seconds: 5),
        autoPlayAnimationDuration: Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
        scrollDirection: Axis.horizontal,
      ),
    );
  }

  Widget _buildFirstViewBody() {
    return SafeArea(
      top: false,
      child: RefreshIndicator(
        child: SingleChildScrollView(
          child: Container(
            height: 725,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: "请联系以下管理员，获得", style: contentTextStyle),
                      TextSpan(text: "密码令牌", style: contentStrongTextStyle),
                      TextSpan(text: "以重置密码。", style: contentTextStyle),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildMainContent(),
                SizedBox(height: 20),
                Text("已有密码令牌？请点击下一步。", style: contentTextStyle),
              ],
            ),
          ),
        ),
        onRefresh: () async {
          await _fetchAdminList();
        },
      ),
    );
  }

  Widget _buildSecondViewBody() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(children: _inputs),
        ),
      ),
    );
  }

  Widget _buildFirstViewBottom() {
    return BottomAppBar(
      color: bgColorLight80,
      padding: EdgeInsets.all(0),
      height: 50,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color.fromRGBO(158, 158, 158, 0.8),
              width: 0.5,
            ),
          ),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(),
            GestureDetector(
              onTap: () async {
                _isChanging = true;
                await Future.delayed(Duration(milliseconds: 100));
                setState(() {});
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "下一步",
                    style: TextStyle(fontSize: 20, fontFamily: 'SmileySans'),
                  ),
                  const Icon(Icons.chevron_right, size: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondViewBottom() {
    return BottomAppBar(
      color: bgColorLight80,
      padding: EdgeInsets.all(0),
      height: 50,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color.fromRGBO(158, 158, 158, 0.8),
              width: 0.5,
            ),
          ),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () async {
                _isChanging = false;
                await Future.delayed(Duration(milliseconds: 100));
                setState(() {});
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.chevron_left, size: 28),
                  const Text(
                    "上一步",
                    style: TextStyle(fontSize: 20, fontFamily: 'SmileySans'),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _resetPassword,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "提交",
                    style: TextStyle(fontSize: 20, fontFamily: 'SmileySans'),
                  ),
                  const Icon(Icons.chevron_right, size: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    _message.value = "正在发送重置密码请求";
    showMessageDialog(context, _message);
    final success = await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return await ApiAuth.resetPassword(_controllers.asTextMap);
      }),
      initMessageList: [],
      messageList: ["重置密码中.", "重置密码中..", "重置密码中..."],
      successMessage: "重置密码成功",
      successMessageDuration: Duration(milliseconds: 300),
      failMessageDuration: Duration(milliseconds: 800),
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _message.dispose();
  }
}
