import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/theme.dart';

class TaskCHeckPage extends StatefulWidget {
  const TaskCHeckPage({super.key});

  @override
  State<TaskCHeckPage> createState() => _TaskCHeckPageState();
}

class _TaskCHeckPageState extends State<TaskCHeckPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text("更改密码", style: titleTextStyle),
            Icon(Icons.edit),
          ],
        ),
        centerTitle: true,
        bottom: bottomLine,
      ),
    );
  }
}
