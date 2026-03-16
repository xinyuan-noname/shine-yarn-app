import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shine/components/message_card.dart';
import 'package:shine/components/notice_card.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';

class MessageView extends StatelessWidget {
  final RefreshCallback onRefresh;
  final List<MessageStorageData> messageList;
  final List<TaskStorageData> taskNoticeList;
  final VoidCallback? deleteCallback;
  const MessageView({
    super.key,
    required this.onRefresh,
    required this.messageList,
    this.deleteCallback,
    required this.taskNoticeList,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (taskNoticeList.isNotEmpty)
          CarouselSlider(
            items: taskNoticeList
                .map((taskData) => NoticeCard(taskData: taskData))
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
              enableInfiniteScroll: false
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
