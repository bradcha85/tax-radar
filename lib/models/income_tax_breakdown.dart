class IncomeTaxBreakdown {
  final int annualRevenue;
  final int expenses;
  final int taxableIncome;
  final double? simpleExpenseRate;
  final int personalDeduction;
  final int yellowUmbrellaAnnual;
  final int taxBase;
  final int incomeTax;
  final int localTax;

  const IncomeTaxBreakdown({
    required this.annualRevenue,
    required this.expenses,
    required this.taxableIncome,
    this.simpleExpenseRate,
    required this.personalDeduction,
    required this.yellowUmbrellaAnnual,
    required this.taxBase,
    required this.incomeTax,
    required this.localTax,
  });

  int get totalTax => incomeTax + localTax;
}
