import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/routes.dart';
import 'package:shine/theme.dart';

class FlagView extends StatelessWidget {
  const FlagView({super.key});

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
              child: TabBarView(children: [SizedBox(), _buildToolBoxWidget()]),
            ),
          ],
        ),
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
              Row(
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
              SizedBox(height: 2),
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
                      globalNavigatorKey.currentState?.pushNamed('/tool/convert/pdf');
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
