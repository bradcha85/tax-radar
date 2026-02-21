import 'package:flutter_test/flutter_test.dart';
import 'package:tax_radar/models/business.dart';
import 'package:tax_radar/models/deemed_purchase.dart';
import 'package:tax_radar/models/monthly_expenses.dart';
import 'package:tax_radar/models/monthly_sales.dart';
import 'package:tax_radar/utils/tax_calculator.dart';

void main() {
  group('TaxCalculator.computeVatBreakdown', () {
    test('의제매입 공제: 한도 미만이면 전액 공제(9/109 특례)', () {
      final business = Business(
        businessType: 'restaurant',
        taxType: 'general',
        vatInclusive: true,
      );

      final breakdown = TaxCalculator.computeVatBreakdown(
        business: business,
        salesList: [
          MonthlySales(yearMonth: DateTime(2026, 1, 1), totalSales: 110000000),
        ],
        expensesList: const <MonthlyExpenses>[],
        deemedPurchases: [
          DeemedPurchase(yearMonth: DateTime(2026, 1, 1), amount: 10000000),
        ],
        filledMonths: 6,
        totalPeriodMonths: 6,
        asOf: DateTime(2026, 2, 16),
      );

      // taxBase = 100,000,000 → 우대한도(75%) 75,000,000보다 작으므로 10,000,000 전액
      // 음식점 + taxBase ≤ 4억 + asOf ~2026 → 9/109 특례 적용
      expect(breakdown.deemedPurchaseCredit, equals(825688));
    });

    test('의제매입 공제: 한도 초과 시 min(매입, 과세표준×한도율)', () {
      final business = Business(
        businessType: 'restaurant',
        taxType: 'general',
        vatInclusive: true,
      );

      final breakdown = TaxCalculator.computeVatBreakdown(
        business: business,
        salesList: [
          MonthlySales(yearMonth: DateTime(2026, 1, 1), totalSales: 110000000),
        ],
        expensesList: const <MonthlyExpenses>[],
        deemedPurchases: [
          DeemedPurchase(yearMonth: DateTime(2026, 1, 1), amount: 100000000),
        ],
        filledMonths: 6,
        totalPeriodMonths: 6,
        asOf: DateTime(2026, 2, 16),
      );

      // taxBase = 100,000,000 → 우대한도(75%) 75,000,000에 9/109 특례 적용
      expect(breakdown.deemedPurchaseCredit, equals(6192661));
    });

    test('의제매입 공제: 2027년 9/109 일몰 후 8/108, 우대한도율 유지', () {
      final business = Business(
        businessType: 'restaurant',
        taxType: 'general',
        vatInclusive: true,
      );

      final breakdown = TaxCalculator.computeVatBreakdown(
        business: business,
        salesList: [
          MonthlySales(yearMonth: DateTime(2027, 1, 1), totalSales: 110000000),
        ],
        expensesList: const <MonthlyExpenses>[],
        deemedPurchases: [
          DeemedPurchase(yearMonth: DateTime(2027, 1, 1), amount: 100000000),
        ],
        filledMonths: 6,
        totalPeriodMonths: 6,
        asOf: DateTime(2027, 1, 1),
      );

      // taxBase = 100,000,000 → 우대한도(75%) 75,000,000에 8/108 적용
      // asOf 2027 → 9/109 일몰, 8/108 복귀. 우대한도율은 2027.12.31까지 유지
      expect(breakdown.deemedPurchaseCredit, equals(5555556));
    });

    test('의제매입 공제: 2028년 우대한도율 일몰 후 기본한도율 복귀', () {
      final business = Business(
        businessType: 'restaurant',
        taxType: 'general',
        vatInclusive: true,
      );

      final breakdown = TaxCalculator.computeVatBreakdown(
        business: business,
        salesList: [
          MonthlySales(yearMonth: DateTime(2028, 1, 1), totalSales: 110000000),
        ],
        expensesList: const <MonthlyExpenses>[],
        deemedPurchases: [
          DeemedPurchase(yearMonth: DateTime(2028, 1, 1), amount: 100000000),
        ],
        filledMonths: 6,
        totalPeriodMonths: 6,
        asOf: DateTime(2028, 1, 1),
      );

      // taxBase = 100,000,000 → 기본한도(50%) 50,000,000에 8/108 적용
      // asOf 2028 → 우대한도율·9/109 모두 일몰
      expect(breakdown.deemedPurchaseCredit, equals(3703704));
    });

    test('9/109 특례: 음식점 과세표준 4억 이하 (2026년)', () {
      final business = Business(
        businessType: 'restaurant',
        taxType: 'general',
        vatInclusive: true,
      );

      final breakdown = TaxCalculator.computeVatBreakdown(
        business: business,
        salesList: [
          MonthlySales(yearMonth: DateTime(2026, 3, 1), totalSales: 110000000),
        ],
        expensesList: const <MonthlyExpenses>[],
        deemedPurchases: [
          DeemedPurchase(yearMonth: DateTime(2026, 3, 1), amount: 10000000),
        ],
        filledMonths: 6,
        totalPeriodMonths: 6,
        asOf: DateTime(2026, 6, 30),
      );

      // taxBase = 100,000,000 ≤ 4억 → 9/109
      // credit = (10,000,000 × 9 / 109).round() = 825688
      expect(breakdown.deemedPurchaseCredit, equals(825688));
    });

    test('카페는 9/109 특례 미적용 (8/108 유지)', () {
      final business = Business(
        businessType: 'cafe',
        taxType: 'general',
        vatInclusive: true,
      );

      final breakdown = TaxCalculator.computeVatBreakdown(
        business: business,
        salesList: [
          MonthlySales(yearMonth: DateTime(2026, 1, 1), totalSales: 110000000),
        ],
        expensesList: const <MonthlyExpenses>[],
        deemedPurchases: [
          DeemedPurchase(yearMonth: DateTime(2026, 1, 1), amount: 10000000),
        ],
        filledMonths: 6,
        totalPeriodMonths: 6,
        asOf: DateTime(2026, 2, 16),
      );

      // cafe → 8/108, 우대한도율 75%
      // taxBase = 100,000,000, deemedCapBase = 75,000,000
      // base = 10,000,000 (< cap)
      // credit = (10,000,000 × 8 / 108).round() = 740741
      expect(breakdown.deemedPurchaseCredit, equals(740741));
    });

    test('신카 발행세액공제: 2026년 연간 한도(1천만) 적용', () {
      final business = Business(
        businessType: 'restaurant',
        taxType: 'general',
        vatInclusive: true,
      );

      final breakdown = TaxCalculator.computeVatBreakdown(
        business: business,
        salesList: [
          MonthlySales(
            yearMonth: DateTime(2026, 1, 1),
            totalSales: 2000000000,
            cardSales: 1000000000,
            cashReceiptSales: 0,
            otherCashSales: 1000000000,
          ),
        ],
        expensesList: const <MonthlyExpenses>[],
        deemedPurchases: const <DeemedPurchase>[],
        filledMonths: 6,
        totalPeriodMonths: 6,
        asOf: DateTime(2026, 2, 16),
      );

      // 1,000,000,000 × 1.3% = 13,000,000 → 연간 한도 10,000,000
      expect(breakdown.cardIssuanceCredit, equals(10000000));
    });

    test('신카 발행세액공제: 카드 공제 누적분 반영(remaining cap)', () {
      final business = Business(
        businessType: 'restaurant',
        taxType: 'general',
        vatInclusive: true,
      );

      final breakdown = TaxCalculator.computeVatBreakdown(
        business: business,
        salesList: [
          MonthlySales(
            yearMonth: DateTime(2026, 8, 1),
            totalSales: 2000000000,
            cardSales: 1000000000,
            cashReceiptSales: 0,
            otherCashSales: 1000000000,
          ),
        ],
        expensesList: const <MonthlyExpenses>[],
        deemedPurchases: const <DeemedPurchase>[],
        filledMonths: 6,
        totalPeriodMonths: 6,
        cardCreditUsedThisYear: 9000000,
        asOf: DateTime(2026, 8, 16),
      );

      // remaining cap = 1,000,000
      expect(breakdown.cardIssuanceCredit, equals(1000000));
    });

    test('VAT 미포함 입력 시 신카 공제는 VAT 포함 금액으로 환산', () {
      final business = Business(
        businessType: 'restaurant',
        taxType: 'general',
        vatInclusive: false,
      );

      final breakdown = TaxCalculator.computeVatBreakdown(
        business: business,
        salesList: [
          MonthlySales(
            yearMonth: DateTime(2026, 1, 1),
            totalSales: 100000000,
            cardSales: 100000000,
            cashReceiptSales: 0,
            otherCashSales: 0,
          ),
        ],
        expensesList: const <MonthlyExpenses>[],
        deemedPurchases: const <DeemedPurchase>[],
        filledMonths: 6,
        totalPeriodMonths: 6,
        asOf: DateTime(2026, 2, 16),
      );

      // 카드 발급금액은 통상 VAT 포함: 100,000,000 × 1.1 × 1.3% = 1,430,000
      expect(breakdown.cardIssuanceCredit, equals(1430000));
    });
  });
}
