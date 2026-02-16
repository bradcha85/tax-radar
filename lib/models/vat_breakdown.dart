class VatBreakdown {
  final int totalSales;
  final int cardSales;
  final int cashReceiptSales;
  final int taxableExpenses;
  final int deemedPurchaseAmount;

  final int salesTax;
  final int purchaseTax;
  final int deemedPurchaseCredit;
  final int cardIssuanceCredit;

  /// 음수면 환급(마이너스) 가능. UI에서는 0으로 클램프해서 표시할 수 있음.
  final int estimatedVat;

  /// 과세표준(공급가액). 의제매입 한도율/공제율 판정에 사용.
  final int taxBase;

  const VatBreakdown({
    required this.totalSales,
    required this.cardSales,
    required this.cashReceiptSales,
    required this.taxableExpenses,
    required this.deemedPurchaseAmount,
    required this.salesTax,
    required this.purchaseTax,
    required this.deemedPurchaseCredit,
    required this.cardIssuanceCredit,
    required this.estimatedVat,
    required this.taxBase,
  });

  int get otherCashSales => totalSales - cardSales - cashReceiptSales;
}

