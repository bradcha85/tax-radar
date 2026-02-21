class MonthlySales {
  DateTime yearMonth; // YYYY-MM-01
  int totalSales; // in won
  int? cardSales;
  int? cashReceiptSales;
  int? otherCashSales;

  MonthlySales({
    required this.yearMonth,
    required this.totalSales,
    this.cardSales,
    this.cashReceiptSales,
    this.otherCashSales,
  });

  /// 카드 매출 비율 (0.0 ~ 1.0)
  double get cardRatio {
    if (totalSales == 0) return 0.75;
    return (cardSales ?? (totalSales * 0.75).round()) / totalSales;
  }

  Map<String, dynamic> toJson() => {
    'yearMonth': yearMonth.toIso8601String(),
    'totalSales': totalSales,
    'cardSales': cardSales,
    'cashReceiptSales': cashReceiptSales,
    'otherCashSales': otherCashSales,
  };

  factory MonthlySales.fromJson(Map<String, dynamic> json) => MonthlySales(
    yearMonth: DateTime.tryParse(json['yearMonth'] as String? ?? '') ?? DateTime(2000, 1, 1),
    totalSales: json['totalSales'] as int? ?? 0,
    cardSales: json['cardSales'] as int?,
    cashReceiptSales: json['cashReceiptSales'] as int?,
    otherCashSales: json['otherCashSales'] as int?,
  );
}
