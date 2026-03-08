import 'package:shine/storage/message_storage.dart';

Future<int> countMessageBadge() async {
  final messageList = await MessageStorage.getAllMessage();
  return messageList.where((m) => !m.readed).length;
}
