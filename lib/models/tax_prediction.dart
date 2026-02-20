class TaxPrediction {
  String taxType; // 'vat', 'income_tax'
  String period; // e.g., '2025-1기', '2025년'
  int predictedMin;
  int predictedMax;
  int accuracyScore; // 0~100
  int? actualAmount;
  bool isRefund;

  TaxPrediction({
    required this.taxType,
    required this.period,
    required this.predictedMin,
    required this.predictedMax,
    required this.accuracyScore,
    this.actualAmount,
    this.isRefund = false,
  });

  /// 범위 중간값
  int get midPoint => (predictedMin + predictedMax) ~/ 2;

  /// 범위 폭
  int get range => predictedMax - predictedMin;
}
