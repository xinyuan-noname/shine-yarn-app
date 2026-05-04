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

class SchedulePointData {
  final List<SchedulePointItem> bonusItems; // 加分项列表
  final List<SchedulePointItem> deductionItems; // 扣分项列表

  const SchedulePointData({
    required this.bonusItems,
    required this.deductionItems,
  });

  factory SchedulePointData.fromMap(Map<String, dynamic> json) {
    final bonusList = json['bonusItems'] as List;
    final deductionList = json['deductionItems'] as List;

    return SchedulePointData(
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
      'bonusItems': bonusItems.map((e) => e.toMap()).toList(),
      'deductionItems': deductionItems.map((e) => e.toMap()).toList(),
    };
  }

  SchedulePointData copyWith({
    List<SchedulePointItem>? bonusItems,
    List<SchedulePointItem>? deductionItems,
  }) {
    return SchedulePointData(
      bonusItems: bonusItems ?? this.bonusItems,
      deductionItems: deductionItems ?? this.deductionItems,
    );
  }

  @override
  String toString() {
    return 'SchedulePointData(bonusItems: $bonusItems, deductionItems: $deductionItems)';
  }
}
