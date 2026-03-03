import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/theme.dart';

Widget _buildBottomSheetItem({
  required IconData icon,
  required String title,
  GestureTapCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkColorPurple, mainColorPurple],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: bgColorLight),
          const SizedBox(height: 4),
          Text(
            title,
            style: bottomSheetGridTitleTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

void showTaskGridBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: darkColorPurple,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildBottomSheetItem(
              icon: Icons.checklist,
              title: '任务清查',
              onTap: () async{
                Navigator.pop(context);
                final result = await showDropDownDialog<String>(
                  context: context,
                  title: "选择清查的范围",
                  items: [
                    ("entire", "所有学生"),
                    ("male", "所有男生"),
                    ("female", "所有女生"),
                    ("position", "所有班委"),
                    ("admin", "所有管理员"),
                  ],
                  initialValue: "all",
                );
                print(result);
              },
            ),
          ],
        ),
      );
    },
  );
}
