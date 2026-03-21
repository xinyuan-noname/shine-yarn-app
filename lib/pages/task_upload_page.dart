import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:shine/cache/user_cache.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/file_display_bar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/mime_type_dropdown.dart';
import 'package:shine/components/task.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_task.dart';
import 'package:shine/services/api_task_upload.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/storage/profile_storage.dart';
import 'package:shine/storage/semester_storage.dart';
import 'package:shine/storage/subject_storage.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/async_utils.dart';
import 'package:shine/utils/debouncer_utils.dart';
import 'package:shine/utils/file_utils.dart';
import 'package:shine/utils/image.dart';
import 'package:shine/utils/server.dart';
import 'package:shine/utils/share_utils.dart';
import 'package:shine/utils/time_utils.dart';
import 'package:shine/utils/upload_utils.dart';
import 'package:shine/worker/worker.dart';
import 'package:week_of_year/date_week_extensions.dart';

class TaskUploadPage extends StatefulWidget {
  const TaskUploadPage({super.key});

  @override
  State<TaskUploadPage> createState() => _TaskUploadPageState();
}

class _NameNode {
  int _deleteEmptyTimes = 0;
  final bool isText;
  String value;
  String? content;
  TextEditingController? controller;
  FocusNode? focusNode;
  Function(int, _NameNode)? onDelete;
  Debouncer? debouncer;
  _NameNode({
    required this.value,
    this.content,
    this.isText = true,
    this.onDelete,
  }) {
    if (isText) {
      controller = TextEditingController(text: content);
      debouncer = Debouncer();
      focusNode = FocusNode(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.backspace ||
                event.logicalKey == LogicalKeyboardKey.delete) {
              if (controller!.text.isEmpty) {
                _deleteEmptyTimes++;
              } else {
                _deleteEmptyTimes = 0;
              }
              if (onDelete != null) {
                onDelete!(_deleteEmptyTimes, this);
              }
            }
          }
          return KeyEventResult.ignored;
        },
      );
    }
  }

  dispose() {
    controller?.dispose();
    focusNode?.dispose();
    debouncer?.dispose();
  }
}

class _TaskUploadPageState extends State<TaskUploadPage> {
  final GlobalKey _key = GlobalKey();
  int? _taskId;

  final ValueNotifier<String> _message = ValueNotifier("");
  UploadTaskStorageData? _previousData;
  String _selectedMimeType = "";
  String _username = "";
  String _major = "";
  String _class = "";
  String _academy = "";
  String _id = "";
  DateTime _semesterStartedAt = DateTime.now();
  UniqueKey _startedKey = UniqueKey();
  UniqueKey _endedKey = UniqueKey();
  DateTime _startedAt = DateTime.now();
  DateTime _finisheddAt = DateTime.now().add(Duration(days: 1));
  final List<_NameNode> _nameNodeList = [_NameNode(value: "")];
  final List<String> _subjectNameList = [];
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _taskNameController = TextEditingController();
  final Debouncer _debouncerS = Debouncer();
  final Debouncer _debouncerE = Debouncer();
  final Debouncer _debouncerRefresh = Debouncer();
  final List<UploadData> _uploadDataList = [];
  final List<Map<String, dynamic>> _allUserList = UserCache.getUserList();
  List<Map<String, dynamic>> get _unfinishedUserList => _allUserList
      .where(
        (user) => _uploadDataList.every(
          (uploadData) => uploadData.uploadId != user['id'],
        ),
      )
      .toList();
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    AsyncUtils.postFrame(() async {
      showLoadingDialog(
        context: context,
        message: _message,
        request: Future(() async {
          await _initProfileData();
          await _handleArgs();
          if (_taskId != null) {
            await _syncUploadData();
          }
          return null;
        }),
      );
    });
  }

  Future _syncUploadData() async {
    _uploadDataList.clear();
    final result = await Worker.syncUploadsByTaskId(_taskId!);
    if (result is List<UploadData>) {
      _uploadDataList.addAll(result);
    }
    if (mounted) setState(() {});
  }

  void _refreshUploadData() {
    if (_taskId == null) return;
    _debouncerRefresh.run(() async {
      _syncUploadData();
    });
  }

  Future<void> _initProfileData() async {
    final results = await Future.wait([
      SubjectStorage.getCurrentSubjectName(),
      ProfileStorage.getName(),
      ProfileStorage.getMajor(),
      ProfileStorage.getClass(),
      ProfileStorage.getAcademy(),
      ProfileStorage.getId(),
      SemesterStorage.getCurrentSemesterStartedAt(),
    ]);
    _subjectNameList.clear();
    _subjectNameList.addAll(results[0] as List<String>);
    _username = results[1] as String;
    _major = results[2] as String;
    _class = results[3] as String;
    _academy = results[4] as String;
    _id = results[5] as String;
    _semesterStartedAt = results[6] as DateTime? ?? DateTime.now();
  }

  Future<void> _handleArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is TaskUploadPageArgs) {
      _taskId = args.data.id;
      _startedAt = args.data.createdAt!;
      _finisheddAt = args.data.endedAt;
      _taskNameController.text = args.data.title;
      _subjectController.text = args.data.subjectName;
      _selectedMimeType = args.data.mimetype;
      _parseNameNodeList(args.data.format);
      _startedKey = UniqueKey();
      _endedKey = UniqueKey();
      _previousData = args.data;
      setState(() {});
    }
  }

  void ensureTaskName() {
    if (_taskNameController.text.isEmpty) {
      _taskNameController.text =
          "${_startedAt.year}-${_startedAt.month}-${_startedAt.day}-${_startedAt.hour}-${_startedAt.minute}任务";
    }
  }

  Future _createTask() async {
    if (_taskId != null) return;
    ensureTaskName();

    _message.value = "正在上传任务中";
    showMessageDialog(context, _message);
    await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        final result = await ApiTask.createUploadTask(
          title: _taskNameController.text,
          startedAt: _startedAt,
          endedAt: _finisheddAt,
          subjectName: _subjectController.text,
          mimetype: _selectedMimeType,
          format: _nameNodeList
              .map((node) {
                if (node.isText) {
                  return node.controller!.text;
                }
                return "%tag[${node.value}]%";
              })
              .join(""),
          source: "admin",
        );
        if (result is String) return result;
        if (result is int) {
          _taskId = result;
        }
        return null;
      }),
      initMessageList: [],
      messageList: ["正在上传中.", "正在上传中..", "正在上传中..."],
      successMessage: "上传成功",
      successMessageDuration: Duration(milliseconds: 300),
      failMessageDuration: Duration(milliseconds: 800),
    );
    Navigator.of(context).pop();
    if (DateTime.now().isAfter(_startedAt)) {
      await WsTask.sendRemind(
        msg: "有新作业“${_taskNameController.text}”发布，请尽快完成",
        targetList: await ProfileStorage.getUserIdList(),
        level: 6,
      );
    } else if (DateTime.now().isBefore(_startedAt)) {
      await WsTask.sendRemind(
        msg:
            "有新作业“${_taskNameController.text}”将于${getDayDifferenceString(_startedAt)}发布，请注意",
        targetList: await ProfileStorage.getUserIdList(),
        level: 3,
      );
    }
  }

  Future _updateTask() async {
    if (_taskId == null) return;
    ensureTaskName();
    _message.value = "正在更改任务中";
    showMessageDialog(context, _message);
    await sendRequestAndChangeMessage(
      _message,
      request: Future(() async {
        return await ApiTask.updateTask(
          title: _taskNameController.text,
          startedAt: _startedAt,
          endedAt: _finisheddAt,
          subjectName: _subjectController.text,
          mimetype: _selectedMimeType,
          taskType: "upload",
          taskId: _taskId!,
          format: _nameNodeList
              .map((node) {
                if (node.isText) {
                  return node.controller!.text;
                }
                return "%tag[${node.value}]%";
              })
              .join(""),
        );
      }),
      initMessageList: [],
      messageList: ["正在更改中.", "正在更改中..", "正在更改中..."],
      successMessage: "更改成功",
      successMessageDuration: Duration(milliseconds: 300),
      failMessageDuration: Duration(milliseconds: 800),
    );
    Navigator.of(context).pop();
    if (DateTime.now().isAfter(_startedAt)) {
      await WsTask.sendRemind(
        msg: "作业“${_taskNameController.text}”设置有改动，请注意",
        targetList: await ProfileStorage.getUserIdList(),
        level: 5,
      );
    } else {
      final startedAtP = _previousData?.createdAt;
      if (startedAtP == null) return;
      if (startedAtP.day == _startedAt.day &&
          startedAtP.difference(_startedAt).inDays < 1) {
        return;
      }
      await WsTask.sendRemind(
        msg:
            "作业“${_taskNameController.text}”改为于${getDayDifferenceString(_startedAt)}发布",
        targetList: await ProfileStorage.getUserIdList(),
        level: 3,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: RepaintBoundary(
        key: _key,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: _buildAppBar(),
          body: DefaultTabController(
            length: 2,
            child: SafeArea(
              child: Column(
                children: [
                  TabBar(
                    tabs: [Text("提交设置"), Text("完成情况")],
                    labelStyle: tabLabelStyle,
                    padding: EdgeInsets.only(top: 2),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [_buildUploadWidget(), _buildFinishWidget()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text("任务提交", style: titleTextStyle),
      centerTitle: true,
      bottom: bottomLine,
    );
  }

  Widget _buildUploadWidget() {
    return Container(
      padding: bodyPadding,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
          gradient: whiteLinearGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 2),
                hintText: "请输入本次作业提交的标题",
                hintStyle: textFieldHintStyle,
              ),
              textAlign: TextAlign.start,
              style: textFieldStyle,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              controller: _taskNameController,
            ),
            const SizedBox(height: 4),
            bottomLine,
            const SizedBox(height: 4),
            Text(
              "科目:",
              style: const TextStyle(fontFamily: "SmileySans", fontSize: 16),
            ),
            TypeAheadField<String>(
              builder: (context, controller, focusNode) {
                return TextField(
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 2),
                    hintText: "请输入科目",
                    hintStyle: const TextStyle(
                      fontFamily: "SmileySans",
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontFamily: "SmileySans",
                    fontSize: 16,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  controller: controller,
                  focusNode: focusNode,
                );
              },
              controller: _subjectController,
              itemBuilder: (context, value) {
                return ListTile(title: Text(value, style: labelStyle));
              },
              onSelected: (value) {
                _subjectController.text = value;
              },
              suggestionsCallback: (search) {
                if (search.isEmpty) return _subjectNameList;
                return _subjectNameList.where((sub) {
                  int i = 0;
                  for (final char in search.split("")) {
                    i = sub.substring(i).indexOf(char);
                    if (i == -1) return false;
                  }
                  return true;
                }).toList();
              },
            ),
            bottomLineSmall,
            const SizedBox(height: 4),
            const Text("文件类型:", style: labelStyle),
            MimeTypeDropdown(
              value: _selectedMimeType,
              onChanged: (String newValue) {
                _selectedMimeType = newValue;
                setState(() {});
              },
            ),
            bottomLineSmall,
            const SizedBox(height: 4),
            const Text(
              "文件名格式:",
              style: TextStyle(fontFamily: "SmileySans", fontSize: 16),
            ),
            _buildFileNameWidget(),
            _buildFormationWidget(),
            const SizedBox(height: 2),
            SizedBox(
              height: 40,
              child: Text(
                "示例：${_joinNameNode()}",
                style: const TextStyle(
                  fontFamily: "SmileySans",
                  color: Colors.grey,
                  fontSize: 12,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 2,
              ),
            ),
            bottomLineSmall,
            const SizedBox(height: 4),
            Text(
              "开始时间:${_getDateInfoStr(_startedAt)}",
              style: TextStyle(fontFamily: "SmileySans", fontSize: 16),
            ),
            SizedBox(
              height: 30,
              child: CupertinoDatePicker(
                key: _startedKey,
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _startedAt,
                use24hFormat: true,
                onDateTimeChanged: (DateTime d) {
                  _debouncerS.run(() {
                    _startedAt = d;
                    setState(() {});
                  });
                },
              ),
            ),
            bottomLineSmall,
            const SizedBox(height: 5),
            Text(
              "截止时间:${_getDateInfoStr(_finisheddAt)}",
              style: TextStyle(fontFamily: "SmileySans", fontSize: 16),
            ),
            SizedBox(
              height: 30,
              child: CupertinoDatePicker(
                key: _endedKey,
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _finisheddAt,
                use24hFormat: true,
                onDateTimeChanged: (DateTime d) {
                  _debouncerE.run(() {
                    _finisheddAt = d;
                    setState(() {});
                  });
                },
              ),
            ),
            const SizedBox(height: 15),
            _taskId == null ? _buildUploadButton() : _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  String _getDateInfoStr(DateTime d) {
    String result = getDayDifferenceString(d);
    result += "(第${_getSemesterWeek(d)}周-星期${getCnWeekDayName(d)})";
    return result;
  }

  int _getSemesterWeek(DateTime d) {
    final s = _semesterStartedAt.weekOfYear;
    final e = d.weekOfYear;
    return e - s + 1;
  }

  Widget _buildUpdateButton() {
    return Container(
      alignment: Alignment(0, 0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          side: BorderSide(color: deepColorBlue80, width: 2.0),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: () async {
          await _updateTask();
          setState(() {});
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.upload, size: 24, color: deepColorBlue),
            SizedBox(width: 10),
            Text(
              '更改作业',
              style: TextStyle(
                color: deepColorBlue,
                fontSize: 20,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      alignment: Alignment(0, 0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          side: BorderSide(color: deepColorPurple, width: 2.0),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: () async {
          _createTask();
          setState(() {});
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.upload, size: 24, color: deepColorPurple),
            SizedBox(width: 10),
            Text(
              '发布作业',
              style: TextStyle(
                color: deepColorPurple,
                fontSize: 20,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileNameWidget() {
    final List<Widget> children = [];
    final List<Widget> wl = List.generate(_nameNodeList.length, (index) {
      final node = _nameNodeList[index];
      if (node.isText) {
        return IntrinsicWidth(
          child: TextField(
            scrollPadding: EdgeInsets.all(0),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(0),
              hintText: index == 0 && _nameNodeList.length == 1
                  ? "请设置文件名"
                  : null,
              hintStyle: const TextStyle(
                fontFamily: "SmileySans",
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            textAlign: TextAlign.start,
            style: const TextStyle(fontFamily: "SmileySans", fontSize: 16),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[\s$\{\}]')),
            ],
            controller: node.controller,
            focusNode: node.focusNode,
            onChanged: (_) {
              node.debouncer?.run(() {
                setState(() {});
              });
            },
          ),
        );
      }
      return GestureDetector(
        child: Container(
          padding: EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: _formationGradientMap[node.value],
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            node.content ?? "",
            style: const TextStyle(
              fontFamily: "SmileySans",
              fontSize: 16,
              color: bgColorLight,
            ),
          ),
        ),
        onTap: () {
          _nameNodeList.removeRange(index, index + 2);
          setState(() {});
        },
      );
    }).toList();
    children.addAll(wl);
    return GestureDetector(
      onTap: () {
        final last = _nameNodeList.elementAt(_nameNodeList.length - 1);
        if (last.focusNode != null) {
          FocusScope.of(context).unfocus();
          last.focusNode?.requestFocus();
        }
      },
      child: Container(
        padding: EdgeInsets.all(1),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(gradient: whiteLinearGradient),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: children),
        ),
      ),
    );
  }

  Widget _buildFinishWidget() {
    final unfinishedUserList = _unfinishedUserList;
    final avatarList = List.generate(unfinishedUserList.length, (index) {
      final user = unfinishedUserList[index];
      final String id = user["id"];
      final String username = user["username"];
      return SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NetworkAvatar(id: id),
            Text(
              username,
              style: const TextStyle(fontFamily: "SmileySans", fontSize: 12),
            ),
          ],
        ),
      );
    });

    return RefreshIndicator(
      onRefresh: () async {
        _refreshUploadData();
      },
      child: ListView(
        children: [
          ExpansionTile(
            initiallyExpanded: true,
            childrenPadding: EdgeInsets.symmetric(horizontal: 8),
            title: Text(
              "完成的同学(${_uploadDataList.length}人)",
              style: expansionListTitleStyle,
            ),
            children: [
              Wrap(
                children: _uploadDataList
                    .map(
                      (uploadData) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        margin: EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          gradient: whiteLinearGradient,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: mainColorGrey60),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Column(
                                  children: [
                                    NetworkAvatar(id: uploadData.uploadId),
                                    Text(
                                      UserCache.getUsername(
                                            uploadData.uploadId,
                                          ) ??
                                          "未知用户",
                                      style: const TextStyle(
                                        fontFamily: "SmileySans",
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: FileDisplayBar(
                                    fileName: uploadData.uploadFileName,
                                    maxLines: 2,
                                    onPress: () async {
                                      if (_taskId == null) return;
                                      final fileName =
                                          uploadData.uploadFileName;
                                      if (fileName.endsWith(".pdf")) {
                                        gotoViewPdfUrl(
                                          "/task/upload/file/$_taskId/${ApiService.userId}",
                                        );
                                      } else if (isImageFile(fileName)) {
                                        gotoViewImageUrl(
                                          "/task/upload/file/$_taskId/${ApiService.userId}",
                                        );
                                      } else if (isDocument(fileName)) {
                                        gotoViewPdfUrl(
                                          "/task/upload/view/document/$_taskId/${ApiService.userId}",
                                        );
                                      } else {
                                        showToast(msg: "暂不支持预览");
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            bottomLineSmall,
                            SizedBox(height: 2),
                            Container(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () async {
                                  final result = await showPromptDialog(
                                    context: context,
                                    title:
                                        '请输入打回${UserCache.getUsername(uploadData.uploadId)}任务的原因？',
                                    label: '打回原因',
                                  );
                                  if (result != null) {
                                    final msg =
                                        await ApiTaskUpload.deleteUpload(
                                          taskId: uploadData.taskId,
                                          uploadId: uploadData.uploadId,
                                        );
                                    showToast(
                                      msg:
                                          msg ??
                                          "${UserCache.getUsername(uploadData.uploadId)}的任务已删除成功",
                                    );
                                    if (mounted) {
                                      _refreshUploadData();
                                    }
                                    WsTask.sendRemind(
                                      msg:
                                          '你的“${_taskNameController.text}”任务被打回，请重新提交。\n打回原因：$result',
                                      targetList: [uploadData.uploadId],
                                      level: 6,
                                    );
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: redLinearGradient,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    "打回任务",
                                    style: TextStyle(
                                      fontFamily: "SmileySans",
                                      fontSize: 14,
                                      color: bgColorLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(
              "未完成的同学(${unfinishedUserList.length}人)",
              style: expansionListTitleStyle,
            ),
            children: [Wrap(direction: Axis.horizontal, children: avatarList)],
          ),
        ],
      ),
    );
  }

  final List<List<String>> _formationInfo = [
    ["academy", "学院"],
    ["major", "专业"],
    ["class", "班级"],
    ["username", "姓名"],
    ["id", "学号"],
    ["free", "自由输入"],
  ];
  final Map<String, Gradient> _formationGradientMap = {
    "academy": purpleLinearGradient,
    "major": purpleLinearGradientReversed,
    "class": purpleLinearGradientStrong,
    "username": blueLinearGradientReversed,
    "id": blueLinearGradient,
    "free": redLinearGradientReversed,
  };
  Widget _buildFormationWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _formationInfo.map((e) {
        return GestureDetector(
          child: Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: _formationGradientMap[e[0]],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              e[1],
              style: const TextStyle(
                fontFamily: "SmileySans",
                fontSize: 16,
                color: bgColorLight,
              ),
            ),
          ),
          onTap: () {
            final buttonNode = _NameNode(
              value: e[0],
              content: e[1],
              isText: false,
            );
            final textNode = _NameNode(
              value: "",
              onDelete: (t, n) {
                if (t >= 1) {
                  _nameNodeList.remove(buttonNode);
                  _nameNodeList.remove(n);
                  setState(() {});
                }
              },
            );
            _nameNodeList.add(buttonNode);
            _nameNodeList.add(textNode);
            setState(() {});
            final last = _nameNodeList.elementAt(_nameNodeList.length - 1);
            if (last.focusNode != null) {
              FocusScope.of(context).unfocus();
              last.focusNode?.requestFocus();
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color.fromRGBO(158, 158, 158, 0.8),
            width: 0.5,
          ),
        ),
      ),
      child: BottomAppBar(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 30),
        color: bgColorLight60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildBottomItem(
              onTap: () async {
                final result = await showPromptDialog(
                  context: context,
                  title: "请设置提醒消息, 点击确定以发送",
                  label: "提醒消息",
                  initValue: "请尽快完成作业“${_taskNameController.text}”",
                );
                if (result == null) return;
                try {
                  await WsTask.sendRemind(
                    msg: result,
                    targetList: _unfinishedUserList
                        .map((e) => e['username'])
                        .whereType<String>()
                        .toList(),
                    level: 5,
                  );
                  showToast(msg: "发送成功");
                } catch (err) {
                  showToast(msg: "发送失败, ${err.toString()}");
                }
              },
              icon: Icons.notifications_outlined,
              title: '一键提醒',
            ),
            buildBottomItem(
              onTap: () async {
                if (_taskId == null) {
                  showToast(msg: "该任务暂未发布");
                  return;
                }
                if (_unfinishedUserList.isNotEmpty) {
                  final result = await showConfrimDialog(
                    context: context,
                    title: '确认要打包吗',
                    content: '还有${_unfinishedUserList.length}人未完成该任务',
                  );
                  if (!result) return;
                }
                Worker.startDownload(
                  url: '/task/upload/zip/$_taskId',
                  filename:
                      '${_taskNameController.text}-${DateTime.now().millisecondsSinceEpoch ~/ 1000}.zip',
                );
              },
              icon: Icons.download_outlined,
              title: '打包文件',
            ),
            buildBottomItem(
              onTap: () async {
                final image = await captureWidgetToPng(globalKey: _key);
                if (image == null) {
                  showToast(msg: "获取屏幕信息失败");
                  return;
                }
                await shareImage(
                  image: image,
                  name: "draw_task.png",
                  title: _taskNameController.text,
                );
              },
              icon: Icons.share_outlined,
              title: '分享到...',
            ),
          ],
        ),
      ),
    );
  }

  void _parseNameNodeList(String fileName) {
    for (final node in _nameNodeList) {
      node.dispose();
    }
    _nameNodeList.clear();
    _nameNodeList.add(_NameNode(value: ""));

    final pattern = RegExp(r'%tag\[([a-z]+)\]%|([^%]+)');
    final matches = pattern.allMatches(fileName);
    for (final match in matches) {
      final tagKey = match.group(1);
      final textContent = match.group(2);

      if (tagKey != null) {
        final formationEntry = _formationInfo.firstWhere(
          (e) => e[0] == tagKey,
          orElse: () => ['free', '自由输入'],
        );

        final buttonNode = _NameNode(
          value: tagKey,
          content: formationEntry[1],
          isText: false,
        );
        _nameNodeList.add(buttonNode);

        final textNode = _NameNode(
          value: "",
          onDelete: (t, n) {
            if (t >= 1) {
              _nameNodeList.remove(buttonNode);
              _nameNodeList.remove(n);
              setState(() {});
            }
          },
        );
        _nameNodeList.add(textNode);
      } else if (textContent != null && textContent.isNotEmpty) {
        final textNode = _NameNode(
          value: "",
          content: textContent,
          isText: true,
          onDelete: (t, n) {
            if (t >= 1) {
              _nameNodeList.remove(n);
              setState(() {});
            }
          },
        );
        _nameNodeList.add(textNode);
      }
    }
    setState(() {});
  }

  String _joinNameNode() {
    String result = "";
    for (final node in _nameNodeList) {
      if (node.isText) {
        result += node.controller!.text;
      } else {
        switch (node.value) {
          case "academy":
            result += _academy;
            break;
          case "username":
            result += _username;
            break;
          case "major":
            result += _major;
            break;
          case "class":
            result += _class;
            break;
          case "id":
            result += _id;
            break;
          case "free":
            result += 'xxx';
            break;
        }
      }
    }
    result +=
        getExtensionListFromMimeType(_selectedMimeType)?.firstOrNull ?? ".*";
    return result;
  }

  @override
  void dispose() {
    super.dispose();
    _subjectController.dispose();
    for (final node in _nameNodeList) {
      node.dispose();
    }
  }
}

class TaskUploadPageArgs {
  final UploadTaskStorageData data;
  const TaskUploadPageArgs({required this.data});
}
