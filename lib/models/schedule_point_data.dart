class SchedulePointItem {
  final String id;
  final String name;
  final bool isBonus; // true为加分项，false为扣分项
  final double weight; // 加分项的权重或扣分项的占比

  const SchedulePointItem({
    required this.id,
    required this.name,
    required this.isBonus,
    required this.weight,
  });

  factory SchedulePointItem.fromMap(Map<String, dynamic> json) {
    return SchedulePointItem(
      id: json['id'] as String,
      name: json['name'] as String,
      isBonus: json['isBonus'] as bool,
      weight: (json['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isBonus': isBonus,
      'weight': weight,
    };
  }

  SchedulePointItem copyWith({
    String? id,
    String? name,
    bool? isBonus,
    double? weight,
  }) {
    return SchedulePointItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isBonus: isBonus ?? this.isBonus,
      weight: weight ?? this.weight,
    );
  }

  @override
  String toString() {
    return 'SchedulePointItem(id: $id, name: $name, isBonus: $isBonus, weight: $weight)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SchedulePointItem &&
        other.id == id &&
        other.name == name &&
        other.isBonus == isBonus &&
        other.weight == weight;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, isBonus, weight);
  }
}

/// 某一天的评分数据（包含完成状态和得分）
class DailySchedulePoint {
  final bool isCompleted; // 是否完成
  final double score; // 得分

  const DailySchedulePoint({
    this.isCompleted = false,
    this.score = 0.0,
  });

  factory DailySchedulePoint.fromMap(Map<String, dynamic> json) {
    return DailySchedulePoint(
      isCompleted: json['isCompleted'] as bool? ?? false,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isCompleted': isCompleted,
      'score': score,
    };
  }

  DailySchedulePoint copyWith({
    bool? isCompleted,
    double? score,
  }) {
    return DailySchedulePoint(
      isCompleted: isCompleted ?? this.isCompleted,
      score: score ?? this.score,
    );
  }
}

class SchedulePointData {
  // 星期一到星期日的评分规则（索引0=星期一，索引6=星期日）
  final List<SchedulePointRule> weekRules;
  
  // 每日评分记录（key格式: "YYYY-MM-DD"，value为该天的评分数据）
  final Map<String, DailySchedulePoint> dailyRecords;

  const SchedulePointData({
    required this.weekRules,
    this.dailyRecords = const {},
  });

  factory SchedulePointData.fromMap(Map<String, dynamic> json) {
    final weekRulesList = json['weekRules'] as List;
    final dailyRecordsMap = json['dailyRecords'] as Map<String, dynamic>? ?? {};
    
    return SchedulePointData(
      weekRules: weekRulesList
          .map((e) => SchedulePointRule.fromMap(e as Map<String, dynamic>))
          .toList(),
      dailyRecords: dailyRecordsMap.map(
        (key, value) => MapEntry(
          key,
          DailySchedulePoint.fromMap(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekRules': weekRules.map((e) => e.toMap()).toList(),
      'dailyRecords': dailyRecords.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  SchedulePointData copyWith({
    List<SchedulePointRule>? weekRules,
    Map<String, DailySchedulePoint>? dailyRecords,
  }) {
    return SchedulePointData(
      weekRules: weekRules ?? this.weekRules,
      dailyRecords: dailyRecords ?? this.dailyRecords,
    );
  }

  @override
  String toString() {
    return 'SchedulePointData(weekRules: $weekRules, dailyRecords: $dailyRecords)';
  }
}

/// 某一天的评分规则
class SchedulePointRule {
  final int weekday; // 星期几 (1-7)
  final List<SchedulePointItem> bonusItems; // 加分项列表
  final List<SchedulePointItem> deductionItems; // 扣分项列表

  const SchedulePointRule({
    required this.weekday,
    required this.bonusItems,
    required this.deductionItems,
  });

  factory SchedulePointRule.fromMap(Map<String, dynamic> json) {
    final bonusList = json['bonusItems'] as List;
    final deductionList = json['deductionItems'] as List;

    return SchedulePointRule(
      weekday: json['weekday'] as int,
      bonusItems: bonusList
          .map((e) => SchedulePointItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      deductionItems: deductionList
          .map((e) => SchedulePointItem.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekday': weekday,
      'bonusItems': bonusItems.map((e) => e.toMap()).toList(),
      'deductionItems': deductionItems.map((e) => e.toMap()).toList(),
    };
  }

  SchedulePointRule copyWith({
    int? weekday,
    List<SchedulePointItem>? bonusItems,
    List<SchedulePointItem>? deductionItems,
  }) {
    return SchedulePointRule(
      weekday: weekday ?? this.weekday,
      bonusItems: bonusItems ?? this.bonusItems,
      deductionItems: deductionItems ?? this.deductionItems,
    );
  }

  @override
  String toString() {
    return 'SchedulePointRule(weekday: $weekday, bonusItems: $bonusItems, deductionItems: $deductionItems)';
  }
}
