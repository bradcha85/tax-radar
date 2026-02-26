import 'package:flutter_test/flutter_test.dart';

import 'package:tax_radar/models/precision_tax.dart';
import 'package:tax_radar/utils/precision_tax_engine.dart';

int _truncate10(int value) {
  if (value >= 0) return (value ~/ 10) * 10;
  final absValue = value.abs();
  return -((absValue ~/ 10) * 10);
}

void main() {
  group('PrecisionTaxEngine (감면·공제)', () {
    PrecisionTaxDraft baseDraft() {
      return PrecisionTaxDraft.initial(now: DateTime(2026, 2, 25)).copyWith(
        taxYear: 2025,
        businessInputMode: BusinessInputMode.annual,
        bookkeeping: true,
        annualSalesVatMode: VatInclusionChoice.excluded,
        annualSales: const NumericField(
          value: 500000000,
          status: PrecisionValueStatus.complete,
        ),
        annualExpenses: const NumericField(
          value: 200000000,
          status: PrecisionValueStatus.complete,
        ),
        spouseSelection: SelectionState.no,
        yellowUmbrellaSelection: SelectionState.no,
        additionalTaxCredit: const NumericField(
          value: 0,
          status: PrecisionValueStatus.complete,
        ),
        ruralSpecialTax: const NumericField(
          value: 0,
          status: PrecisionValueStatus.complete,
        ),
      );
    }

    test('startup relief reduces national tax (50%)', () {
      final base = PrecisionTaxEngine.calculate(
        draft: baseDraft(),
        businessType: 'restaurant',
      ).breakdown;
      expect(base.taxReliefTotal, 0);
      expect(base.nationalTax, base.calculatedIncomeTax);

      final withStartup = PrecisionTaxEngine.calculate(
        draft: baseDraft().copyWith(
          startupTaxReliefRate: StartupTaxReliefRate.rate50,
        ),
        businessType: 'restaurant',
      ).breakdown;

      final expected = _truncate10(((base.calculatedIncomeTax * 50) / 100).round())
          .clamp(0, base.calculatedIncomeTax);
      expect(withStartup.startupTaxRelief, expected);
      expect(withStartup.nationalTax, base.calculatedIncomeTax - expected);
    });

    test('employment increase credit reduces national tax (per employee)', () {
      final base = PrecisionTaxEngine.calculate(
        draft: baseDraft(),
        businessType: 'restaurant',
      ).breakdown;

      final withEmployment = PrecisionTaxEngine.calculate(
        draft: baseDraft().copyWith(
          employmentIncreaseCount: const NumericField(
            value: 2,
            status: PrecisionValueStatus.complete,
          ),
        ),
        businessType: 'restaurant',
      ).breakdown;

      const raw = 2 * 10000000;
      final expected = _truncate10(raw).clamp(0, base.calculatedIncomeTax);
      expect(withEmployment.employmentIncreaseTaxCredit, expected);
      expect(withEmployment.nationalTax, base.calculatedIncomeTax - expected);
    });

    test('child tax credit formula applies by eligible count', () {
      final base = PrecisionTaxEngine.calculate(
        draft: baseDraft(),
        businessType: 'restaurant',
      ).breakdown;

      PrecisionTaxBreakdown calc(int count) {
        return PrecisionTaxEngine.calculate(
          draft: baseDraft().copyWith(
            childTaxCreditCount: NumericField(
              value: count,
              status: PrecisionValueStatus.complete,
            ),
          ),
          businessType: 'restaurant',
        ).breakdown;
      }

      final with1 = calc(1);
      expect(with1.childTaxCredit, 250000);
      expect(with1.nationalTax, base.calculatedIncomeTax - 250000);

      final with2 = calc(2);
      expect(with2.childTaxCredit, 550000);
      expect(with2.nationalTax, base.calculatedIncomeTax - 550000);

      final with3 = calc(3);
      expect(with3.childTaxCredit, 950000);
      expect(with3.nationalTax, base.calculatedIncomeTax - 950000);
    });

    test('rural special tax adds to totalTax', () {
      final base = PrecisionTaxEngine.calculate(
        draft: baseDraft(),
        businessType: 'restaurant',
      ).breakdown;

      final withRuralTax = PrecisionTaxEngine.calculate(
        draft: baseDraft().copyWith(
          ruralSpecialTax: const NumericField(
            value: 1230000,
            status: PrecisionValueStatus.complete,
          ),
        ),
        businessType: 'restaurant',
      ).breakdown;

      expect(withRuralTax.ruralSpecialTax, 1230000);
      expect(withRuralTax.totalTax, base.totalTax + 1230000);
    });
  });
}
