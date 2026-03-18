import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shine/components/message_card.dart';
import 'package:shine/components/notice_card.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/upload_utils.dart';

class MessageView extends StatelessWidget {
  final RefreshCallback onRefresh;
  final List<MessageStorageData> messageList;
  final List<TaskStorageData> taskNoticeList;
  final List<UploadData> uploadDataList;
  final VoidCallback? deleteCallback;
  const MessageView({
    super.key,
    this.deleteCallback,
    required this.onRefresh,
    required this.messageList,
    required this.taskNoticeList,
    required this.uploadDataList,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (taskNoticeList.isNotEmpty)
          CarouselSlider(
            items: taskNoticeList
                .map(
                  (taskData) => NoticeCard(
                    taskData: taskData,
                    uploadData: uploadDataList.firstWhereOrNull(
                      (e) => e.taskId == taskData.id,
                    ),
                  ),
                )
                .toList(),
            options: CarouselOptions(
              height: 160,
              enlargeFactor: 0.15,
              enlargeCenterPage: true,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 5),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              scrollDirection: Axis.horizontal,
              enableInfiniteScroll: false,
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: mainColorPurple90,
            backgroundColor: bgColorLight,
            onRefresh: onRefresh,
            child: ListView.builder(
              padding: viewPadding,
              itemCount: max(messageList.length, 1),
              itemBuilder: (context, index) {
                if (messageList.isEmpty) {
                  if (taskNoticeList.isEmpty) {
                    return Container(
                      alignment: Alignment.center,
                      child: Text("消息很干净哟", style: viewEmptyTextStyle),
                    );
                  }
                  return SizedBox();
                }
                final data = messageList[index];
                return MessageCard(
                  messageData: data,
                  deleteCallback: deleteCallback,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
