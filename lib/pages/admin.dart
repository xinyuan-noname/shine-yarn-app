import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/theme.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("管理界面", style: titleTextStyle),
        centerTitle: true,
        bottom: bottomLine,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          child: ListView.builder(
            itemCount: 1, 
            itemBuilder: (context, index) {
              return ListTile(title: Text('Item $index'));
            },
          ),
          onRefresh: () async {
            await Future.delayed(Duration(seconds: 1));
          },
        ),
      ),
    );
  }
}
