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

  factory MonthlyExpenses.fromJson(Map<String, dynamic> json) => MonthlyExpenses(
    yearMonth: DateTime.parse(json['yearMonth'] as String),
    totalExpenses: json['totalExpenses'] as int? ?? 0,
    taxableExpenses: json['taxableExpenses'] as int?,
  );
}
