import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/static_header_expansion.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/models/to_do_item_data.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/time_utils.dart';

class FlagView extends StatelessWidget {
  final List<ToDoItemData> unfinishedItemList;
  final List<ToDoItemData> finishedItemList;
  final RefreshCallback onRefresh;
  final VoidCallback updateFinishedStatus;
  const FlagView({
    super.key,
    required this.unfinishedItemList,
    required this.finishedItemList,
    required this.onRefresh,
    required this.updateFinishedStatus,
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
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  children: [
                    ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
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
                        if (unfinishedItemList.isEmpty) return null;
                        final item = unfinishedItemList[index];
                        return GestureDetector(
                          onLongPress: () {},
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: StaticHeaderExpansion(
                              leading: Icon(Icons.panorama_fish_eye),
                              onLeadingTap: () async {
                                await MessageStorage.changeFinishedStatus(
                                  itemId: item.itemId,
                                  finished: true,
                                );
                                updateFinishedStatus();
                              },
                              initiallyExpanded: true,
                              title: Text(
                                item.title,
                                style: expansionListTitleStyle,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              children: [
                                Text(
                                  item.content.trim(),
                                  style: const TextStyle(
                                    fontFamily: "SmileySans",
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      item.source,
                                      style: const TextStyle(
                                        fontFamily: "SmileySans",
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: bgColorLight,
                                        shadows: [deepPurpleShadow],
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      getLocalTimeString(
                                        DateTime.fromMillisecondsSinceEpoch(
                                          item.ts,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontFamily: "SmileySans",
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: bgColorLight,
                                        shadows: [deepPurpleShadow],
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: finishedItemList.length,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final item = finishedItemList[index];
                        return GestureDetector(
                          onLongPress: () {},
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: StaticHeaderExpansion(
                              leading: Icon(
                                Icons.check_circle_outline,
                                color: mainColorGrey80,
                              ),
                              onLeadingTap: () async {
                                await MessageStorage.changeFinishedStatus(
                                  itemId: item.itemId,
                                  finished: false,
                                );
                                updateFinishedStatus();
                              },
                              trailingColor: mainColorGrey80,
                              initiallyExpanded: true,
                              title: Text(
                                item.title,
                                style: expansionListTitleLineThroughStyle,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              children: [
                                Text(
                                  item.content.trim(),
                                  style: const TextStyle(
                                    fontFamily: "SmileySans",
                                    fontSize: 16,
                                    decoration: TextDecoration.lineThrough,
                                    color: mainColorGrey80,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      item.source,
                                      style: const TextStyle(
                                        fontFamily: "SmileySans",
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: bgColorLight,
                                        shadows: [deepPurpleShadow],
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      getLocalTimeString(
                                        DateTime.fromMillisecondsSinceEpoch(
                                          item.ts,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontFamily: "SmileySans",
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: bgColorLight,
                                        shadows: [deepPurpleShadow],
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
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
