class DeemedPurchase {
  DateTime yearMonth;
  int amount; // in won

  DeemedPurchase({required this.yearMonth, required this.amount});

  Map<String, dynamic> toJson() => {
    'yearMonth': yearMonth.toIso8601String(),
    'amount': amount,
  };

  factory DeemedPurchase.fromJson(Map<String, dynamic> json) => DeemedPurchase(
    yearMonth: DateTime.tryParse(json['yearMonth'] as String? ?? '') ?? DateTime(2000, 1, 1),
    amount: json['amount'] as int? ?? 0,
  );
}
