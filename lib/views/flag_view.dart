import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/floating_action_button_widget.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/static_header_expansion.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/models/to_do_item_data.dart';
import 'package:shine/pages/to_do_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_message.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/time_utils.dart';

class FlagView extends StatelessWidget {
  final List<ToDoItemData> unfinishedItemList;
  final List<ToDoItemData> finishedItemList;
  final RefreshCallback onRefresh;
  final VoidCallback updateFinishedStatus;
  final TabController tabController;
  final List<String> subjectsList;
  const FlagView({
    super.key,
    required this.unfinishedItemList,
    required this.finishedItemList,
    required this.onRefresh,
    required this.updateFinishedStatus,
    required this.tabController,
    required this.subjectsList,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          TabBar(
            tabs: [const Text("事项表"), const Text("资源站"), const Text("工具箱")],
            labelStyle: tabLabelStyle,
            padding: const EdgeInsets.only(top: 2),
            controller: tabController,
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _buildToDoListWidget(),
                _buildResourceWidget(),
                _buildToolBoxWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceWidget() {
    return Container(
      padding: bodyPadding,
      child: Container(
        padding: const EdgeInsets.all(10),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: subjectsList.length,
                itemBuilder: (context, index) {
                  if (subjectsList.isEmpty) return null;
                  final subjectName = subjectsList[index];
                  return Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: purpleLinearGradientReversed,
                    ),
                    margin: EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      subjectName,
                      style: const TextStyle(
                        fontFamily: "SmileySans",
                        fontSize: 14,
                        color: bgColorLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 8),
            Container(width: 2, color: mainColorGrey20),
            Expanded(
              flex: 4,
              child: ListView.builder(
                itemCount: max(1, 1),
                itemBuilder: (context, index) {},
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
                          onLongPress: () {
                            _deleteToDoItem(context, item);
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [greyBoxShadow],
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
                              onContentTap: () {
                                _gotoEditToDoItem(item);
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
                                        fontSize: 13,
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
                                        fontSize: 13,
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
                          onLongPress: () {
                            _deleteToDoItem(context, item);
                          },
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
                              onContentTap: () {
                                _gotoEditToDoItem(item);
                              },
                              trailingColor: mainColorGrey80,
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
                                        fontSize: 13,
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
                                        fontSize: 13,
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
            child: FloatingActionButtonWidget(
              onTap: () async {
                if (ApiService.position == null) {
                  showToast(msg: "没有职务的同学不能创建事项");
                  return;
                }
                await globalNavigatorKey.currentState?.pushNamed('/to_do');
              },
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

  void _deleteToDoItem(BuildContext context, ToDoItemData data) async {
    if (ApiService.position == null) return;
    if (ApiService.position != data.source) {
      showToast(msg: "你无法操作其他人发布的代办项！");
      return;
    }
    final result = await showConfirmDialog(
      context: context,
      title: "是否删除“${data.title}”代办项？",
      content: "此操作不可挽回！",
    );
    if (result) {
      final deleteResult = await ApiMessage.deletePublicToDoItem(data.itemId);
      if (deleteResult == null) {
        showToast(msg: "删除代办项成功");
        onRefresh();
      } else {
        showToast(msg: deleteResult);
      }
    }
  }

  void _gotoEditToDoItem(ToDoItemData data) async {
    await globalNavigatorKey.currentState?.pushNamed(
      '/to_do',
      arguments: ToDoPageArgs(data: data),
    );
    onRefresh();
  }
}
