import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/theme.dart';

class FlagView extends StatelessWidget {
  final List unfinishedItemList;
  final List finishedItemList;
  const FlagView({
    super.key,
    required this.unfinishedItemList,
    required this.finishedItemList,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            TabBar(
              tabs: [Text("事项表"), Text("工具箱")],
              labelStyle: tabLabelStyle,
              padding: const EdgeInsets.only(top: 2),
            ),
            Expanded(
              child: TabBarView(
                children: [_buildToDoListWidget(), _buildToolBoxWidget()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToDoListWidget() {
    final isEmpty = unfinishedItemList.isEmpty && finishedItemList.isEmpty;
    return SizedBox.expand(
      child: Stack(
        children: [
          Container(
            padding: bodyPadding,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (!isEmpty)
                        Expanded(
                          child: SearchBar(
                            hintText: '请输入搜索的内容',
                            hintStyle: WidgetStatePropertyAll(
                              const TextStyle(
                                fontFamily: "SmileySans",
                                color: mainColorGrey80,
                              ),
                            ),
                            textStyle: WidgetStatePropertyAll(
                              const TextStyle(fontFamily: "SmileySans"),
                            ),
                            leading: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: whiteLinearGradient,
                              ),
                              child: const Icon(
                                Icons.search,
                                size: normalIconSize,
                              ),
                            ),
                            backgroundColor: WidgetStatePropertyAll(
                              Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: max(1, unfinishedItemList.length),
                      itemBuilder: (context, index) {
                        if (isEmpty) {
                          return Container(
                            alignment: Alignment.center,
                            child: const Text(
                              "暂无事项，快去休息吧！",
                              style: viewEmptyTextStyle,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final item = unfinishedItemList[index];
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: finishedItemList.length,
                      itemBuilder: (context, index) {
                        final item = finishedItemList[index];
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 20,
            child: GestureDetector(
              onTap: () async {
                if (ApiService.position == null) {
                  showToast(msg: "没有职务的同学不能创建事项");
                  return;
                }
                await globalNavigatorKey.currentState?.pushNamed('/to_do');
              },
              child: Container(
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: blueLinearGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: mainColorPurple,
                  size: largeIconSize,
                  shadows: [Shadow(color: Colors.white, blurRadius: 5)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBoxWidget() {
    return SizedBox.expand(
      child: Container(
        padding: bodyPadding,
        child: Container(
          padding: const EdgeInsets.all(20),
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
            gradient: purpleLinearGradientStrong,
          ),
          child: ListView(
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.sync,
                    color: mainColorOrange,
                    size: 17,
                    shadows: [Shadow(color: Colors.grey, blurRadius: 5)],
                  ),
                  Text(
                    "文件转换",
                    style: TextStyle(
                      fontFamily: "SmileySans",
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: mainColorGreenBlue,
                      shadows: [Shadow(color: Colors.grey, blurRadius: 5)],
                    ),
                  ),
                ],
              ),
              bottomLineSmall,
              const SizedBox(height: 2),
              GridView(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  GestureDetector(
                    onTap: () {
                      globalNavigatorKey.currentState?.pushNamed(
                        '/tool/convert/pdf',
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: purpleLinearGradient,
                        border: Border.all(color: mainColorGreenBlue),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: blueLinearGradient80,
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              size: largeIconSize,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            '转为PDF',
                            style: TextStyle(
                              fontFamily: "SmileySans",
                              fontSize: 12,
                              color: bgColorLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
