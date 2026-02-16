class UserProfile {
  bool hasBookkeeping;
  bool dependentsSelf;
  bool hasSpouse;
  int childrenCount;
  bool supportsParents;
  bool yellowUmbrella;
  int? yellowUmbrellaMonthly; // in won
  int? previousVatAmount; // in won

  UserProfile({
    this.hasBookkeeping = false,
    this.dependentsSelf = true,
    this.hasSpouse = false,
    this.childrenCount = 0,
    this.supportsParents = false,
    this.yellowUmbrella = false,
    this.yellowUmbrellaMonthly,
    this.previousVatAmount,
  });

  Map<String, dynamic> toJson() => {
    'hasBookkeeping': hasBookkeeping,
    'dependentsSelf': dependentsSelf,
    'hasSpouse': hasSpouse,
    'childrenCount': childrenCount,
    'supportsParents': supportsParents,
    'yellowUmbrella': yellowUmbrella,
    'yellowUmbrellaMonthly': yellowUmbrellaMonthly,
    'previousVatAmount': previousVatAmount,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    hasBookkeeping: json['hasBookkeeping'] as bool? ?? false,
    dependentsSelf: json['dependentsSelf'] as bool? ?? true,
    hasSpouse: json['hasSpouse'] as bool? ?? false,
    childrenCount: json['childrenCount'] as int? ?? 0,
    supportsParents: json['supportsParents'] as bool? ?? false,
    yellowUmbrella: json['yellowUmbrella'] as bool? ?? false,
    yellowUmbrellaMonthly: json['yellowUmbrellaMonthly'] as int?,
    previousVatAmount: json['previousVatAmount'] as int?,
  );

  /// 인적공제 총액 (원)
  int get personalDeduction {
    int count = 0;
    if (dependentsSelf) count++;
    if (hasSpouse) count++;
    count += childrenCount;
    if (supportsParents) count += 1; // 부모님 1인 기본
    return count * 1500000;
  }

  /// 노란우산공제 연간 (원)
  int get yellowUmbrellaAnnual {
    if (!yellowUmbrella || yellowUmbrellaMonthly == null) return 0;
    return yellowUmbrellaMonthly! * 12;
  }
}
