import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/services/api_semesters.dart';
import 'package:shine/theme.dart';

class SemesterPage extends StatefulWidget {
  const SemesterPage({super.key});

  @override
  State<SemesterPage> createState() => _SemesterPageState();
}

class _SemesterPageState extends State<SemesterPage> {
  final List<List<DateTime>> _phaseList = [
    [DateTime.now(), DateTime.now().add(Duration(minutes: 10))],
  ];
  String _semesterName = '';
  DateTime _startedAt = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Container(
            height: 900,
            padding: bodyPadding,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
                gradient: whiteLinearGradient,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 2),
                      hintText: "请输入本学期名称",
                      hintStyle: textFieldHintStyle,
                    ),
                    textAlign: TextAlign.start,
                    style: textFieldStyle,
                    onChanged: (value) {
                      _semesterName = value;
                    },
                  ),
                  bottomLine,
                  SizedBox(
                    height: 70,
                    child: Column(
                      children: [
                        Text(
                          "学期开始时间：",
                          style: const TextStyle(
                            fontFamily: 'SmileySans',
                            fontSize: 20,
                          ),
                        ),
                        Expanded(
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: _startedAt,
                            use24hFormat: true,
                            onDateTimeChanged: (DateTime d) {
                              _startedAt = d;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  bottomLine,
                  SizedBox(height: 10),
                  _buildSemesterWidget(),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text("学期设置", style: titleTextStyle),
      centerTitle: true,
      bottom: bottomLine,
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      color: bgColorLight60,
      child: ElevatedButton(
        onPressed: () async {
          final result = await ApiSemesters.createSemester(
            semesterName: _semesterName,
            startedAt: _startedAt,
            phaseList: _phaseList,
          );
          if (result is String) {
            showToast(msg: result);
          } else {
            showToast(msg: "创建新学期成功");
          }
        },
        style: ElevatedButton.styleFrom(
          side: BorderSide(color: mainColorPurple80, width: 2.0),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: const Text(
          "提交",
          style: TextStyle(
            color: deepColorPurple,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterWidget() {
    return Expanded(
      child: ListView.builder(
        itemCount: _phaseList.length + 1,
        itemBuilder: (context, index) {
          if (index == _phaseList.length) {
            return GestureDetector(
              onTap: () {
                _phaseList.add([
                  _phaseList[index - 1][1].add(Duration(minutes: 10)),
                  _phaseList[index - 1][1].add(Duration(minutes: 55)),
                ]);
                setState(() {});
              },
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 2),
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_circle_outline_outlined,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Text("添加选项", style: textFieldHintStyle),
                  ],
                ),
              ),
            );
          }
          return GestureDetector(
            onTap: () {
              if (index > 0) {
                _phaseList.removeAt(index);
                setState(() {});
              }
            },
            child: Container(
              height: 35,
              margin: EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 1, color: bgColorLight),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  index > 0
                      ? const Icon(
                          Icons.remove_circle_outline,
                          color: Color.fromRGBO(158, 158, 158, 1),
                        )
                      : const Icon(
                          Icons.panorama_fish_eye,
                          color: Color.fromRGBO(158, 158, 158, 0.5),
                        ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 1),
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(fontFamily: "SmileySans", fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: _phaseList[index][0],
                      use24hFormat: true,
                      onDateTimeChanged: (DateTime d) {
                        _phaseList[index][0] = d;
                      },
                    ),
                  ),
                  Text("-"),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: _phaseList[index][1],
                      use24hFormat: true,
                      onDateTimeChanged: (DateTime d) {
                        _phaseList[index][1] = d;
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
