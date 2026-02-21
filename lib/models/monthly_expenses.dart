class MonthlyExpenses {
  DateTime yearMonth;
  int totalExpenses; // in won
  int? taxableExpenses;

  MonthlyExpenses({
    required this.yearMonth,
    required this.totalExpenses,
    this.taxableExpenses,
  });

  Map<String, dynamic> toJson() => {
    'yearMonth': yearMonth.toIso8601String(),
    'totalExpenses': totalExpenses,
    'taxableExpenses': taxableExpenses,
  };

  factory MonthlyExpenses.fromJson(Map<String, dynamic> json) =>
      MonthlyExpenses(
        yearMonth: DateTime.tryParse(json['yearMonth'] as String? ?? '') ?? DateTime(2000, 1, 1),
        totalExpenses: json['totalExpenses'] as int? ?? 0,
        taxableExpenses: json['taxableExpenses'] as int?,
      );
}
