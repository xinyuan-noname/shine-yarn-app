import 'package:flutter/material.dart';

class SelectAllButton extends StatelessWidget {
  final List<int> selectedIndexList;
  final List<dynamic> allItemList;
  final VoidCallback callback;
  final Color? unselectedColor;
  final Color? selectedColor;
  const SelectAllButton({
    super.key,
    required this.selectedIndexList,
    required this.allItemList,
    required this.callback,
    this.unselectedColor,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return selectedIndexList.length != allItemList.length
        ? IconButton(
            onPressed: () {
              selectedIndexList.clear();
              selectedIndexList.addAll(
                List.generate(allItemList.length, (int index) => index),
              );
              callback();
            },
            icon: Icon(Icons.check_box_outline_blank, color: unselectedColor),
          )
        : IconButton(
            onPressed: () {
              selectedIndexList.clear();
              callback();
            },
            icon: Icon(Icons.check_box_outlined, color: selectedColor),
          );
  }
}
