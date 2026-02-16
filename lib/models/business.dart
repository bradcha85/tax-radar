class Business {
  String businessType; // 'restaurant', 'cafe', 'other'
  String taxType; // 'general', 'simplified', 'unknown'
  bool vatInclusive;

  Business({
    this.businessType = 'restaurant',
    this.taxType = 'general',
    this.vatInclusive = true,
  });

  Map<String, dynamic> toJson() => {
    'businessType': businessType,
    'taxType': taxType,
    'vatInclusive': vatInclusive,
  };

  factory Business.fromJson(Map<String, dynamic> json) => Business(
    businessType: json['businessType'] as String? ?? 'restaurant',
    taxType: json['taxType'] as String? ?? 'general',
    vatInclusive: json['vatInclusive'] as bool? ?? true,
  );
}
