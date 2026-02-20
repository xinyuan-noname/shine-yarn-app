import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
              title: Text('从相册选择'),
              onTap: () async {
                Navigator.pop(context);
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
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('拍照'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (image != null) {
                  handleSelectedImage(image);
                }
              },
            ),
          ],
        ),
      );
    },
  );
}
