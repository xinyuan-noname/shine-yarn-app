import 'package:flutter/material.dart';
import 'package:shine/theme.dart';

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

class CardDeleteButton extends StatelessWidget {
  final VoidCallback? onDelete;
  final Color color;
  final double size;
  final EdgeInsetsGeometry margin;

  const CardDeleteButton({
    super.key,
    this.onDelete,
    this.color = bgColorLight,
    this.size = 50,
    this.margin = const EdgeInsets.symmetric(horizontal: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: mainColorRed, shape: BoxShape.circle),
      margin: margin,
      child: IconButton(
        padding: const EdgeInsets.all(0),
        onPressed: onDelete,
        icon: Icon(Icons.delete, color: color),
        iconSize: size * 0.9,
      ),
    );
  }
}
