import '../models/monthly_sales.dart';
import '../models/monthly_expenses.dart';
import '../models/deemed_purchase.dart';
import '../models/user_profile.dart';
import '../models/business.dart';
import '../models/tax_prediction.dart';
import '../models/vat_breakdown.dart';
import '../models/income_tax_breakdown.dart';

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
    int filledMonths = 6,
    int totalPeriodMonths = 6,
    int cardCreditUsedThisYear = 0,
    DateTime? asOf,
  }) {
    final breakdown = computeVatBreakdown(
      business: business,
      salesList: salesList,
      expensesList: expensesList,
      deemedPurchases: deemedPurchases,
      filledMonths: filledMonths,
      totalPeriodMonths: totalPeriodMonths,
      cardCreditUsedThisYear: cardCreditUsedThisYear,
      asOf: asOf,
    );

    // ⑤ 납부세액
    final estimatedVat = breakdown.estimatedVat;
    final isRefund = estimatedVat < 0;
    final base = estimatedVat.abs();

    // 정확도에 따라 범위 조정
    final marginRate = _getMarginRate(accuracyScore);
    final min = (base * (1 - marginRate)).round().clamp(0, base * 3);
    final max = (base * (1 + marginRate)).round();

    return TaxPrediction(
      taxType: 'vat',
      period: period,
      predictedMin: min < 0 ? 0 : min,
      predictedMax: max < 0 ? 0 : max,
      accuracyScore: accuracyScore,
      isRefund: isRefund,
    );
  }

  static VatBreakdown computeVatBreakdown({
    required Business business,
    required List<MonthlySales> salesList,
    required List<MonthlyExpenses> expensesList,
    required List<DeemedPurchase> deemedPurchases,
    int filledMonths = 6,
    int totalPeriodMonths = 6,
    int cardCreditUsedThisYear = 0,
    DateTime? asOf,
  }) {
    final asOfDate = asOf ?? DateTime.now();

    // 외삽 계수: 입력된 월 → 과세기간(기본 6개월) 전체 추정
    final scale = (filledMonths > 0 && filledMonths < totalPeriodMonths)
        ? totalPeriodMonths / filledMonths
        : 1.0;

    // 과세기간 합산 (외삽 적용)
    final rawSales = salesList.fold<int>(0, (sum, s) => sum + s.totalSales);
    final totalSales = (rawSales * scale).round();
    final rawCardSales = salesList.fold<int>(
      0,
      (sum, s) => sum + (s.cardSales ?? (s.totalSales * 0.75).round()),
    );
    final cardSales = (rawCardSales * scale).round();
    final rawCashReceiptSales = salesList.fold<int>(
      0,
      (sum, s) => sum + (s.cashReceiptSales ?? (s.totalSales * 0.10).round()),
    );
    final cashReceiptSales = (rawCashReceiptSales * scale).round();
    final rawExpenses = expensesList.fold<int>(
      0,
      (sum, e) => sum + (e.taxableExpenses ?? e.totalExpenses),
    );
    final taxableExpenses = (rawExpenses * scale).round();
    final rawDeemedAmount = deemedPurchases.fold<int>(
      0,
      (sum, d) => sum + d.amount,
    );
    final deemedPurchaseAmount = (rawDeemedAmount * scale).round();

    // ① 매출세액 = (VAT 포함) 총 매출 ÷ 11
    final salesTax = business.vatInclusive
        ? totalSales ~/ 11
        : (totalSales * 0.1).round();

    // 과세표준(공급가액)
    final taxBase = business.vatInclusive ? totalSales - salesTax : totalSales;

    // ② 매입세액 = 과세 매입 ÷ 11
    final purchaseTax = taxableExpenses ~/ 11;

    // ③ 의제매입세액공제 = min(면세매입액, 과세표준×한도율) × 공제율
    final deemedLimitRate = _getDeemedLimitRate(
      business: business,
      taxBase: taxBase,
      asOf: asOfDate,
    );
    final deemedCreditRate = _getDeemedCreditRate(
      business: business,
      taxBase: taxBase,
      asOf: asOfDate,
    );
    final deemedCapBase = (taxBase * deemedLimitRate).round();
    final deemedBase = deemedPurchaseAmount < deemedCapBase
        ? deemedPurchaseAmount
        : deemedCapBase;
    final deemedCredit = _applyFractionRound(deemedBase, deemedCreditRate);

    // ④ 신용카드 등 발행세액공제 = (카드+현금영수증) × 공제율, 연간 한도 적용
    final cardCreditBase = cardSales + cashReceiptSales;
    final cardCreditBaseVatIncluded = business.vatInclusive
        ? cardCreditBase
        : (cardCreditBase * 1.1).round();
    final cardRate = _getCardIssuanceCreditRate(asOf: asOfDate);
    final annualCap = _getCardIssuanceCreditAnnualCap(asOf: asOfDate);
    final remainingCap = (annualCap - cardCreditUsedThisYear).clamp(
      0,
      annualCap,
    );
    final cardCreditRaw = _applyFractionRound(
      cardCreditBaseVatIncluded,
      cardRate,
    );
    final cardCredit = cardCreditRaw < remainingCap
        ? cardCreditRaw
        : remainingCap;

    // ⑤ 납부세액
    final estimatedVat = salesTax - purchaseTax - deemedCredit - cardCredit;

    return VatBreakdown(
      totalSales: totalSales,
      cardSales: cardSales,
      cashReceiptSales: cashReceiptSales,
      taxableExpenses: taxableExpenses,
      deemedPurchaseAmount: deemedPurchaseAmount,
      salesTax: salesTax,
      purchaseTax: purchaseTax,
      deemedPurchaseCredit: deemedCredit,
      cardIssuanceCredit: cardCredit,
      estimatedVat: estimatedVat,
      taxBase: taxBase,
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
    int filledMonths = 12,
    int totalPeriodMonths = 12,
  }) {
    final breakdown = computeIncomeTaxBreakdown(
      business: business,
      salesList: salesList,
      expensesList: expensesList,
      profile: profile,
      filledMonths: filledMonths,
      totalPeriodMonths: totalPeriodMonths,
    );

    if (breakdown.taxBase <= 0) {
      return TaxPrediction(
        taxType: 'income_tax',
        period: period,
        predictedMin: 0,
        predictedMax: 0,
        accuracyScore: accuracyScore,
      );
    }

    final totalTax = breakdown.totalTax;

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

  static IncomeTaxBreakdown computeIncomeTaxBreakdown({
    required Business business,
    required List<MonthlySales> salesList,
    required List<MonthlyExpenses> expensesList,
    required UserProfile profile,
    int filledMonths = 12,
    int totalPeriodMonths = 12,
  }) {
    // 외삽 계수: 입력된 월 → 연간(12개월) 전체 추정
    final scale = (filledMonths > 0 && filledMonths < totalPeriodMonths)
        ? totalPeriodMonths / filledMonths
        : 1.0;

    // 연간 매출 (VAT 제외, 외삽 적용)
    final totalSalesRaw = salesList.fold<int>(
      0,
      (sum, s) => sum + s.totalSales,
    );
    final scaledSales = (totalSalesRaw * scale).round();
    final annualRevenue = business.vatInclusive
        ? (scaledSales / 1.1).round()
        : scaledSales;

    int expenses;
    double? simpleExpenseRate;
    if (profile.hasBookkeeping) {
      final rawExpenses = expensesList.fold<int>(
        0,
        (sum, e) => sum + e.totalExpenses,
      );
      expenses = (rawExpenses * scale).round();
    } else {
      simpleExpenseRate = _getSimpleExpenseRate(business.businessType);
      expenses = (annualRevenue * simpleExpenseRate).round();
    }

    final taxableIncome = annualRevenue - expenses;
    final personalDeduction = profile.personalDeduction;
    final yellowUmbrellaAnnual = profile.yellowUmbrellaAnnual;
    final taxBase = taxableIncome - personalDeduction - yellowUmbrellaAnnual;

    final incomeTax = taxBase > 0 ? _applyTaxBracket(taxBase) : 0;
    final localTax = (incomeTax * 0.1).round();

    return IncomeTaxBreakdown(
      annualRevenue: annualRevenue,
      expenses: expenses,
      taxableIncome: taxableIncome,
      simpleExpenseRate: simpleExpenseRate,
      personalDeduction: personalDeduction,
      yellowUmbrellaAnnual: yellowUmbrellaAnnual,
      taxBase: taxBase,
      incomeTax: incomeTax,
      localTax: localTax,
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
    final salesScore = totalMonths > 0
        ? (salesMonthsFilled / totalMonths * 100)
        : 0.0;
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

    return (salesPart + expensePart + deemedPart + freshnessPart).round().clamp(
      0,
      100,
    );
  }

  // ============================================================
  // Private helpers
  // ============================================================

  static double _getDeemedLimitRate({
    required Business business,
    required int taxBase,
    required DateTime asOf,
  }) {
    if (taxBase <= 200000000) return 0.50;
    return 0.40;
  }

  static _Fraction _getDeemedCreditRate({
    required Business business,
    required int taxBase,
    required DateTime asOf,
  }) {
    final isRestaurant =
        business.businessType == 'restaurant' ||
        business.businessType == 'cafe';

    if (!isRestaurant) return const _Fraction(2, 102);
    return const _Fraction(8, 108);
  }

  static _Fraction _getCardIssuanceCreditRate({required DateTime asOf}) {
    final specialEnd = DateTime(2026, 12, 31, 23, 59, 59);
    if (!asOf.isAfter(specialEnd)) return const _Fraction(13, 1000); // 1.3%
    return const _Fraction(1, 100); // 1.0%
  }

  static int _getCardIssuanceCreditAnnualCap({required DateTime asOf}) {
    final specialEnd = DateTime(2026, 12, 31, 23, 59, 59);
    if (!asOf.isAfter(specialEnd)) return 10000000;
    return 5000000;
  }

  static int _applyFractionRound(int amount, _Fraction rate) {
    return ((amount * rate.numerator) / rate.denominator).round();
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

class _Fraction {
  final int numerator;
  final int denominator;

  const _Fraction(this.numerator, this.denominator);
}
