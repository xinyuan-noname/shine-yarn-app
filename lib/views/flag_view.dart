import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/file_display_bar.dart';
import 'package:shine/components/floating_action_button_widget.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/link_text.dart';
import 'package:shine/components/static_header_expansion.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/models/to_do_item_data.dart';
import 'package:shine/pages/to_do_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api_message.dart';
import 'package:shine/services/api_resource.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/storage/to_do_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/file_utils.dart';
import 'package:shine/utils/time_utils.dart';
import 'package:shine/utils/to_do_author_utils.dart';
import 'package:shine/utils/to_do_subject_utils.dart';
import 'package:shine/utils/to_do_viewer.dart';

class FlagView extends StatelessWidget {
  final List<ToDoItemData> unfinishedItemList;
  final List<ToDoItemData> finishedItemList;
  final RefreshCallback onRefresh;
  final VoidCallback updateFinishedStatus;
  final TabController tabController;
  final List<String> subjectsList;
  final String currentSubject;
  final Function(String) onChangeSubject;
  final List<String> resourceList;

  /// 事项表筛选用的科目表（课表科目 + 资源站科目）
  final List<String> toDoSubjectList;

  /// 卡片上科目用的简写（科目名 -> 简写），没有对应项时按名字自动缩写
  final Map<String, String> toDoSubjectShortNames;

  /// 事项表当前选中的科目，null 表示「全部」
  final String? toDoSubjectFilter;
  final Function(String?) onChangeToDoSubjectFilter;
  const FlagView({
    super.key,
    required this.unfinishedItemList,
    required this.finishedItemList,
    required this.onRefresh,
    required this.updateFinishedStatus,
    required this.tabController,
    required this.subjectsList,
    required this.currentSubject,
    required this.onChangeSubject,
    required this.resourceList,
    this.toDoSubjectList = const [],
    this.toDoSubjectShortNames = const {},
    this.toDoSubjectFilter,
    required this.onChangeToDoSubjectFilter,
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
                  return GestureDetector(
                    onTap: () {
                      onChangeSubject(subjectName);
                    },
                    child: Container(
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
                        style: currentSubject == subjectName
                            ? const TextStyle(
                                fontFamily: "SmileySans",
                                fontSize: 14.2,
                                color: mainColorGreenBlue,
                              )
                            : const TextStyle(
                                fontFamily: "SmileySans",
                                fontSize: 14,
                                color: bgColorLight,
                              ),
                        textAlign: TextAlign.center,
                      ),
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
                itemCount: max(1, resourceList.length),
                itemBuilder: (context, index) {
                  if (resourceList.isEmpty) {
                    return Text(
                      "暂无相关资源",
                      style: viewEmptyTextStyle,
                      textAlign: TextAlign.center,
                    );
                  }
                  final fileName = resourceList[index];
                  return FileDisplayBar(
                    fileName: fileName,
                    maxLines: 3,
                    onPress: () async {
                      final url =
                          '${ApiResource.baseUrl}/${Uri.encodeComponent(currentSubject)}/${Uri.encodeComponent(fileName)}';
                      gotoViewPdfUrl(
                        url,
                        filename: fileName,
                        downloadUrl: url,
                        downloadable: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToDoListWidget() {
    final allItemList = [...unfinishedItemList, ...finishedItemList];
    final subjectList = collectToDoSubjects(allItemList, toDoSubjectList);
    // 选中的科目即使当前没有事项也保留，方便直接取消筛选
    if (toDoSubjectFilter != null && !subjectList.contains(toDoSubjectFilter)) {
      subjectList.add(toDoSubjectFilter!);
    }
    final unfinishedList = filterToDoListBySubject(
      unfinishedItemList,
      toDoSubjectFilter,
      toDoSubjectList,
    );
    final finishedList = filterToDoListBySubject(
      finishedItemList,
      toDoSubjectFilter,
      toDoSubjectList,
    );
    final isEmpty = unfinishedList.isEmpty && finishedList.isEmpty;
    return SizedBox.expand(
      child: Stack(
        children: [
          Container(
            padding: bodyPadding,
            child: Container(
              padding: const EdgeInsets.all(10),
              // 顶部固定一行科目筛选，列表在下面滚动
              child: Column(
                children: [
                  if (subjectList.isNotEmpty)
                    _buildToDoSubjectFilter(subjectList, allItemList),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: onRefresh,
                      child: ListView(
                        children: [
                          ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: max(1, unfinishedList.length),
                            itemBuilder: (context, index) {
                              if (isEmpty) {
                                return _buildEmptyToDoTip();
                              }
                              if (unfinishedList.isEmpty) return null;
                              final item = unfinishedList[index];
                              final itemSubject = resolveToDoSubject(
                                item,
                                toDoSubjectList,
                              );
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
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: LinkText(
                                            item.title,
                                            style: expansionListTitleStyle,
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            // 标题只有一行，图片标记按文字展示即可
                                            showImages: false,
                                          ),
                                        ),
                                        if (itemSubject != null) ...[
                                          const SizedBox(width: 6),
                                          _buildToDoSubjectTag(
                                            _shortSubjectName(itemSubject),
                                          ),
                                        ],
                                      ],
                                    ),
                                    children: [
                                      LinkText(
                                        item.content.trim(),
                                        style: const TextStyle(
                                          fontFamily: "SmileySans",
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            toDoSourceLabel(item.source),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
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
                            itemCount: finishedList.length,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final item = finishedList[index];
                              final itemSubject = resolveToDoSubject(
                                item,
                                toDoSubjectList,
                              );
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
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: LinkText(
                                            item.title,
                                            style:
                                                expansionListTitleLineThroughStyle,
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            // 标题只有一行，图片标记按文字展示即可
                                            showImages: false,
                                          ),
                                        ),
                                        if (itemSubject != null) ...[
                                          const SizedBox(width: 6),
                                          _buildToDoSubjectTag(
                                            _shortSubjectName(itemSubject),
                                            finished: true,
                                          ),
                                        ],
                                      ],
                                    ),
                                    children: [
                                      LinkText(
                                        item.content.trim(),
                                        style: const TextStyle(
                                          fontFamily: "SmileySans",
                                          fontSize: 16,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: mainColorGrey80,
                                        ),
                                        // 已完成的事项保留删除线，链接依然标蓝可点
                                        linkStyle: const TextStyle(
                                          fontFamily: "SmileySans",
                                          fontSize: 16,
                                          color: mainColorLinkBlue,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationColor: mainColorLinkBlue,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            toDoSourceLabel(item.source),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
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
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 20,
            child: FloatingActionButtonWidget(
              onTap: () async {
                // 所有人都能发布事项，不再限制职务
                await globalNavigatorKey.currentState?.pushNamed('/to_do');
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 事项表的科目筛选行：全部 + 各科目（带事项数量）
  Widget _buildToDoSubjectFilter(
    List<String> subjectList,
    List<ToDoItemData> allItemList,
  ) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToDoSubjectChip(
            label: allSubjectLabel,
            count: allItemList.length,
            selected: toDoSubjectFilter == null,
            onTap: () => onChangeToDoSubjectFilter(null),
          ),
          ...subjectList.map((subject) {
            return _buildToDoSubjectChip(
              label: subject,
              count: countToDoInSubject(allItemList, subject, toDoSubjectList),
              selected: toDoSubjectFilter == subject,
              onTap: () => onChangeToDoSubjectFilter(subject),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildToDoSubjectChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected ? purpleLinearGradientReversed : null,
          color: selected ? null : Colors.white,
          border: Border.all(
            color: selected ? mainColorGreenBlue : mainColorGrey40,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: "SmileySans",
                fontSize: 13,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                color: selected ? mainColorGreenBlue : darkColorPurple,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: "SmileySans",
                fontSize: 11,
                color: selected ? bgColorLight80 : mainColorGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 科目简写：有自定义简写就用它，否则自动截短
  String _shortSubjectName(String subject) {
    final short = toDoSubjectShortNames[subject];
    if (short != null && short.isNotEmpty) return short;
    return abbreviateSubjectName(subject);
  }

  /// 事项所属科目的小标签（用简写，紧跟标题右侧，不额外占一行）
  Widget _buildToDoSubjectTag(String subject, {bool finished = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: finished ? mainColorGrey20 : mainColorGreenBlue30,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        subject,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontFamily: "SmileySans",
          fontSize: 11,
          color: finished ? mainColorGrey : mainColorLinkBlue,
        ),
      ),
    );
  }

  /// 筛选后没有内容时的提示
  Widget _buildEmptyToDoTip() {
    final subject = toDoSubjectFilter;
    if (subject == null) {
      return Container(
        alignment: Alignment.center,
        child: const Text(
          "暂无事项，快去休息吧！",
          style: viewEmptyTextStyle,
          textAlign: TextAlign.center,
        ),
      );
    }
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            "「$subject」暂无事项",
            style: viewEmptyTextStyle,
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () => onChangeToDoSubjectFilter(null),
            child: const Text("查看全部事项"),
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
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(
                    Icons.school,
                    color: mainColorOrange,
                    size: 17,
                    shadows: [Shadow(color: Colors.grey, blurRadius: 5)],
                  ),
                  Text(
                    "学习工具",
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
                        '/tool/karnaugh',
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
                              Icons.grid_on,
                              size: largeIconSize,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            '卡诺图',
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
                  GestureDetector(
                    onTap: () {
                      globalNavigatorKey.currentState?.pushNamed(
                        '/tool/encoder',
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
                              Icons.code,
                              size: largeIconSize,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            '编码器',
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
                  GestureDetector(
                    onTap: () {
                      globalNavigatorKey.currentState?.pushNamed(
                        '/tool/base_converter',
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
                              Icons.swap_horiz,
                              size: largeIconSize,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            '进制转换',
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
    final viewer = await ToDoViewer.load();
    if (!context.mounted) return;
    if (!viewer.canOperate(data.source)) {
      showToast(msg: "只能操作自己发布的事项");
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
        // 同步本地缓存，断网时也不会继续显示已删除的事项
        await ToDoStorage.removeToDoItem(data.itemId);
        showToast(msg: "删除代办项成功");
        onRefresh();
      } else {
        showToast(msg: deleteResult);
      }
    }
  }

  void _gotoEditToDoItem(ToDoItemData data) async {
    final viewer = await ToDoViewer.load();
    if (!viewer.canOperate(data.source)) {
      showToast(msg: "只能编辑自己发布的事项");
      return;
    }
    await globalNavigatorKey.currentState?.pushNamed(
      '/to_do',
      arguments: ToDoPageArgs(data: data),
    );
    onRefresh();
  }
}
