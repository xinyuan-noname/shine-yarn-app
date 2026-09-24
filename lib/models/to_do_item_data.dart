class ToDoItemData {
  final String itemId;
  final String title;
  final String content;
  final String source;
  final int ts;

  const ToDoItemData({
    required this.itemId,
    required this.title,
    required this.content,
    required this.source,
    required this.ts,
  });

  /// 容错解析：字段缺失或类型不符时退化为空串 / 0，避免单条脏数据让整个事项表崩掉
  factory ToDoItemData.fromMap(Map<String, dynamic> json) {
    final ts = json['ts'];
    return ToDoItemData(
      itemId: json['itemId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      ts: ts is int ? ts : (int.tryParse(ts?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'title': title,
      'content': content,
      'source': source,
      'ts': ts,
    };
  }

  @override
  String toString() {
    return 'ToDoItemData(itemId: $itemId, title: $title, content: $content, source: $source, ts: $ts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToDoItemData &&
        other.itemId == itemId &&
        other.title == title &&
        other.content == content &&
        other.source == source &&
        other.ts == ts;
  }

  @override
  int get hashCode {
    return Object.hash(itemId, title, content, source, ts);
  }
}
