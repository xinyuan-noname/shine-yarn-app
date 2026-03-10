import 'package:flutter/material.dart';
import 'package:shine/theme.dart';

class DualColumnList<T> extends StatelessWidget {
  final String leftTitle;
  final String rightTitle;
  final List<T> leftItems;
  final List<T> rightItems;
  final Widget? Function(BuildContext context, T item, int index) leftItemBuilder;
  final Widget? Function(BuildContext context, T item, int index) rightItemBuilder;

  const DualColumnList({
    super.key,
    required this.leftTitle,
    required this.rightTitle,
    required this.leftItems,
    required this.rightItems,
    required this.leftItemBuilder,
    required this.rightItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildHeaderContainer(
                title: leftTitle,
                length: leftItems.length,
                gradient: purpleLinearGradient,
              ),
              const SizedBox(height: 1),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: 16),
                  child: ListView.builder(
                    itemCount: leftItems.length,
                    itemBuilder: (context, index) {
                      final item = leftItems[index];
                      return leftItemBuilder(context, item, index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(width: 2, color: const Color.fromRGBO(189, 189, 189, 0.6)),
        Expanded(
          child: Column(
            children: [
              _buildHeaderContainer(
                title: rightTitle,
                length: rightItems.length,
                color: mainColorPurple,
              ),
              const SizedBox(height: 1),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ListView.builder(
                    itemCount: rightItems.length,
                    itemBuilder: (context, index) {
                      final item = rightItems[index];
                      return rightItemBuilder(context, item, index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderContainer({
    required String title,
    required int length,
    Gradient? gradient,
    Color? color,
  }) {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 15),
      decoration: BoxDecoration(
        gradient: gradient,
        color: color,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
      ),
      child: Text(
        "$title($length)",
        style: listTitleStyle,
      ),
    );
  }
}