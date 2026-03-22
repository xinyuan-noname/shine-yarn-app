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

  factory ToDoItemData.fromMap(Map<String, dynamic> json) {
    return ToDoItemData(
      itemId: json['itemId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      source: json['source'] as String,
      ts: json['ts'] as int,
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