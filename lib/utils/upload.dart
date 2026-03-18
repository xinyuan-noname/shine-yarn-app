class UploadData {
  final int taskId;
  final String uploadId;
  final DateTime uploadAt;
  final String? uploadMessage;
  final String uploadFileName;

  UploadData({
    required this.taskId,
    required this.uploadId,
    required this.uploadAt,
    this.uploadMessage,
    required this.uploadFileName,
  });

  factory UploadData.fromMap(Map<String, dynamic> map) {
    return UploadData(
      taskId: map['taskId'] as int,
      uploadId: map['uploadId'] as String,
      uploadAt: DateTime.fromMillisecondsSinceEpoch(map['uploadAt'] as int),
      uploadMessage: map['uploadMessage'] as String?,
      uploadFileName: map['uploadFileName'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'uploadId': uploadId,
      'uploadAt': uploadAt.millisecondsSinceEpoch,
      'uploadMessage': uploadMessage,
      'uploadFileName': uploadFileName,
    };
  }
}