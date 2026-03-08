import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shine/components/line.dart';
import 'package:shine/theme.dart';

final ImagePicker _picker = ImagePicker();

Future<void> pickImage(
  BuildContext context,
  Function(XFile) handleSelectedImage,
) async {
  await showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_album),
              title: Text('从相册选择', style: bottomListTitleTextStyle),
              onTap: () async {
                Navigator.of(context).pop();
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                  maxWidth: 1000,
                );
                if (image != null) {
                  handleSelectedImage(image);
                }
              },
            ),
            bottomLine,
          ],
        ),
      );
    },
  );
}
