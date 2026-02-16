import '../models/monthly_sales.dart';
import '../models/monthly_expenses.dart';
import '../models/deemed_purchase.dart';
import '../models/user_profile.dart';
import '../models/business.dart';
import '../models/tax_prediction.dart';

class TaxCalculator {
  TaxCalculator._();

  // ============================================================
  // 부가세 계산 (일반과세자)
  // ============================================================

  /// 반기 부가세 예측
  static TaxPrediction calculateVat({
    required Business business,
    required List<MonthlySales> salesList,
    required List<MonthlyExpenses> expensesList,
    required List<DeemedPurchase> deemedPurchases,
    required int accuracyScore,
    required String period,
  }) {
    // 반기 합산
    final totalSales = salesList.fold<int>(0, (sum, s) => sum + s.totalSales);
    final totalCardSales = salesList.fold<int>(
      0,
      (sum, s) => sum + (s.cardSales ?? (s.totalSales * 0.75).round()),
    );
    final totalCashReceiptSales = salesList.fold<int>(
      0,
      (sum, s) => sum + (s.cashReceiptSales ?? (s.totalSales * 0.10).round()),
    );
    final totalExpenses = expensesList.fold<int>(
      0,
      (sum, e) => sum + (e.taxableExpenses ?? e.totalExpenses),
    );
    final totalDeemedAmount = deemedPurchases.fold<int>(
      0,
      (sum, d) => sum + d.amount,
    );

    // ① 매출세액 = 총 매출 ÷ 11
    final salesTax =
        business.vatInclusive ? totalSales ~/ 11 : (totalSales * 0.1).round();

    // ② 매입세액 = 과세 매입 ÷ 11
    final purchaseTax = totalExpenses ~/ 11;

    // ③ 의제매입세액공제
    final annualSales = totalSales * 2; // 반기 → 연간 추정
    final limitRate = _getDeemedLimitRate(annualSales);
    final deemedLimit = (totalDeemedAmount * limitRate).round();
    final deemedCredit = (deemedLimit * 9 / 109).round();

    // ④ 신카발행세액공제 = (카드+현금영수증) × 1.3%, 반기 최대 500만
    final cardCreditBase = totalCardSales + totalCashReceiptSales;
    final cardCredit =
        (cardCreditBase * 0.013).round().clamp(0, 5000000);

    // ⑤ 납부세액
    final estimated = salesTax - purchaseTax - deemedCredit - cardCredit;
    final midPoint = estimated.clamp(0, estimated.abs() * 3);

    // 정확도에 따라 범위 조정
    final marginRate = _getMarginRate(accuracyScore);
    final min = (midPoint * (1 - marginRate)).round().clamp(0, midPoint * 3);
    final max = (midPoint * (1 + marginRate)).round();

    return TaxPrediction(
      taxType: 'vat',
      period: period,
      predictedMin: min < 0 ? 0 : min,
      predictedMax: max < 0 ? 0 : max,
      accuracyScore: accuracyScore,
    );
  }

  // ============================================================
  // 종소세 계산
  // ============================================================

  /// 연간 종소세 예측
  static TaxPrediction calculateIncomeTax({
    required Business business,
    required List<MonthlySales> salesList,
    required List<MonthlyExpenses> expensesList,
    required UserProfile profile,
    required int accuracyScore,
    required String period,
  }) {
    // 연간 매출 (VAT 제외)
    final totalSalesRaw =
        salesList.fold<int>(0, (sum, s) => sum + s.totalSales);
    final annualRevenue =
        business.vatInclusive ? (totalSalesRaw / 1.1).round() : totalSalesRaw;

    int taxableIncome;

    if (profile.hasBookkeeping) {
      // 기장 신고: 매출 - 실제 경비
      final totalExpenses =
          expensesList.fold<int>(0, (sum, e) => sum + e.totalExpenses);
      taxableIncome = annualRevenue - totalExpenses;
    } else {
      // 추계 신고: 매출 × (1 - 단순경비율)
      final expenseRate = _getSimpleExpenseRate(business.businessType);
      taxableIncome = (annualRevenue * (1 - expenseRate)).round();
    }

    // 과세표준 = 소득 - 인적공제 - 노란우산공제
    final taxBase = taxableIncome -
        profile.personalDeduction -
        profile.yellowUmbrellaAnnual;

    if (taxBase <= 0) {
      return TaxPrediction(
        taxType: 'income_tax',
        period: period,
        predictedMin: 0,
        predictedMax: 0,
        accuracyScore: accuracyScore,
      );
    }

    // 세율표 적용
    final incomeTax = _applyTaxBracket(taxBase);
    // 지방소득세 10%
    final localTax = (incomeTax * 0.1).round();
    final totalTax = incomeTax + localTax;

    // 정확도에 따라 범위 조정
    final marginRate = _getMarginRate(accuracyScore);
    final min = (totalTax * (1 - marginRate)).round().clamp(0, totalTax * 3);
    final max = (totalTax * (1 + marginRate)).round();

    return TaxPrediction(
      taxType: 'income_tax',
      period: period,
      predictedMin: min < 0 ? 0 : min,
      predictedMax: max < 0 ? 0 : max,
      accuracyScore: accuracyScore,
    );
  }

  // ============================================================
  // 정확도 점수 계산
  // ============================================================

  static int calculateAccuracy({
    required int salesMonthsFilled, // 0~6 for VAT, 0~12 for income
    required int totalMonths,
    required bool hasExpenses,
    required bool hasDeemedPurchases,
    required DateTime? lastUpdate,
  }) {
    // 매출 데이터 (40%)
    final salesScore =
        totalMonths > 0 ? (salesMonthsFilled / totalMonths * 100) : 0.0;
    final salesPart = salesScore * 0.4;

    // 지출 데이터 (25%)
    final expensePart = hasExpenses ? 25.0 : 0.0;

    // 의제매입 (20%)
    final deemedPart = hasDeemedPurchases ? 20.0 : 0.0;

    // 최신성 (15%)
    double freshnessPart = 0;
    if (lastUpdate != null) {
      final daysSince = DateTime.now().difference(lastUpdate).inDays;
      if (daysSince <= 7) {
        freshnessPart = 15;
      } else if (daysSince <= 30) {
        freshnessPart = 10;
      } else if (daysSince <= 90) {
        freshnessPart = 5;
      }
    }

    return (salesPart + expensePart + deemedPart + freshnessPart)
        .round()
        .clamp(0, 100);
  }

  // ============================================================
  // Private helpers
  // ============================================================

  static double _getDeemedLimitRate(int annualSales) {
    if (annualSales <= 200000000) return 0.65;
    if (annualSales <= 400000000) return 0.60;
    return 0.50;
  }

  static double _getSimpleExpenseRate(String businessType) {
    switch (businessType) {
      case 'restaurant':
        return 0.897;
      case 'cafe':
        return 0.878;
      default:
        return 0.897;
    }
  }

  static int _applyTaxBracket(int taxBase) {
    if (taxBase <= 14000000) {
      return (taxBase * 0.06).round();
    } else if (taxBase <= 50000000) {
      return (taxBase * 0.15 - 1260000).round();
    } else if (taxBase <= 88000000) {
      return (taxBase * 0.24 - 5760000).round();
    } else if (taxBase <= 150000000) {
      return (taxBase * 0.35 - 15440000).round();
    } else if (taxBase <= 300000000) {
      return (taxBase * 0.38 - 19940000).round();
    } else if (taxBase <= 500000000) {
      return (taxBase * 0.40 - 25940000).round();
    } else if (taxBase <= 1000000000) {
      return (taxBase * 0.42 - 35940000).round();
    } else {
      return (taxBase * 0.45 - 65940000).round();
    }
  }

  /// 정확도에 따른 마진율 (낮을수록 범위 넓음)
  static double _getMarginRate(int accuracy) {
    if (accuracy >= 80) return 0.10;
    if (accuracy >= 60) return 0.20;
    if (accuracy >= 40) return 0.30;
    if (accuracy >= 20) return 0.45;
    return 0.60;
  }
}
