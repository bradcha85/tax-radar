import 'package:flutter_test/flutter_test.dart';

import 'package:tax_radar/models/precision_tax.dart';

dynamic _toHiveLike(dynamic value) {
  if (value is Map) {
    return Map<dynamic, dynamic>.fromEntries(
      value.entries.map(
        (entry) => MapEntry(entry.key, _toHiveLike(entry.value)),
      ),
    );
  }
  if (value is List) {
    return value.map(_toHiveLike).toList();
  }
  return value;
}

void main() {
  test('PrecisionTaxDraft restores from Hive-like nested maps', () {
    final monthlyInputs = List<MonthlyBusinessInput>.generate(12, (index) {
      final month = index + 1;
      if (month == 1) {
        return const MonthlyBusinessInput(
          month: 1,
          sales: NumericField(
            value: 10000000,
            status: PrecisionValueStatus.complete,
          ),
          expenses: NumericField(
            value: 7000000,
            status: PrecisionValueStatus.complete,
          ),
        );
      }
      return MonthlyBusinessInput(month: month);
    });

    final draft = PrecisionTaxDraft.initial(now: DateTime(2026, 2, 25))
        .copyWith(
          taxYear: 2025,
          businessInputMode: BusinessInputMode.monthly,
          bookkeeping: true,
          fillMissingMonths: true,
          annualSalesVatMode: VatInclusionChoice.included,
          annualSales: const NumericField(
            value: 980000000,
            status: PrecisionValueStatus.complete,
          ),
          annualExpenses: const NumericField(
            value: 801818182,
            status: PrecisionValueStatus.estimatedIndustry,
          ),
          monthlyBusinessInputs: monthlyInputs,
          hasLaborIncome: true,
          laborIncome: const IncomeCategoryInput(
            enabled: true,
            incomeAmount: NumericField(
              value: 12000000,
              status: PrecisionValueStatus.complete,
            ),
            withholdingTax: NumericField(
              value: 1230000,
              status: PrecisionValueStatus.complete,
            ),
          ),
          spouseSelection: SelectionState.yes,
          childrenCount: const NumericField(
            value: 2,
            status: PrecisionValueStatus.complete,
          ),
          parentsCount: const NumericField(
            value: 1,
            status: PrecisionValueStatus.complete,
          ),
          yellowUmbrellaSelection: SelectionState.yes,
          yellowUmbrellaAnnualPayment: const NumericField(
            value: 3000000,
            status: PrecisionValueStatus.complete,
          ),
          startupTaxReliefRate: StartupTaxReliefRate.rate50,
          childTaxCreditCount: const NumericField(
            value: 3,
            status: PrecisionValueStatus.complete,
          ),
          employmentIncreaseCount: const NumericField(
            value: 2,
            status: PrecisionValueStatus.complete,
          ),
          additionalTaxCredit: const NumericField(
            value: 500000,
            status: PrecisionValueStatus.complete,
          ),
          ruralSpecialTax: const NumericField(
            value: 200000,
            status: PrecisionValueStatus.complete,
          ),
          midtermPrepaymentSelection: SelectionState.yes,
          midtermPrepayment: const NumericField(
            value: 4200000,
            status: PrecisionValueStatus.complete,
          ),
          otherPrepaymentSelection: SelectionState.no,
          otherPrepayment: NumericField.missing,
        );

    final hiveLike = _toHiveLike(draft.toJson()) as Map;
    final restored = PrecisionTaxDraft.fromJson(
      Map<String, dynamic>.from(hiveLike),
    );

    expect(restored.taxYear, draft.taxYear);
    expect(restored.businessInputMode, draft.businessInputMode);
    expect(restored.bookkeeping, true);
    expect(restored.fillMissingMonths, true);
    expect(restored.annualSalesVatMode, VatInclusionChoice.included);
    expect(restored.annualSales.value, 980000000);
    expect(restored.annualSales.status, PrecisionValueStatus.complete);
    expect(restored.annualExpenses.value, 801818182);
    expect(
      restored.annualExpenses.status,
      PrecisionValueStatus.estimatedIndustry,
    );

    expect(restored.monthlyBusinessInputs.length, 12);
    expect(restored.monthlyBusinessInputs.first.month, 1);
    expect(restored.monthlyBusinessInputs.first.sales.value, 10000000);
    expect(restored.monthlyBusinessInputs.first.expenses.value, 7000000);

    expect(restored.hasLaborIncome, true);
    expect(restored.laborIncome.enabled, true);
    expect(restored.laborIncome.incomeAmount.value, 12000000);
    expect(restored.laborIncome.withholdingTax.value, 1230000);

    expect(restored.spouseSelection, SelectionState.yes);
    expect(restored.childrenCount.value, 2);
    expect(restored.parentsCount.value, 1);
    expect(restored.yellowUmbrellaSelection, SelectionState.yes);
    expect(restored.yellowUmbrellaAnnualPayment.value, 3000000);

    expect(restored.startupTaxReliefRate, StartupTaxReliefRate.rate50);
    expect(restored.childTaxCreditCount.value, 3);
    expect(restored.employmentIncreaseCount.value, 2);
    expect(restored.additionalTaxCredit.value, 500000);
    expect(restored.ruralSpecialTax.value, 200000);

    expect(restored.midtermPrepaymentSelection, SelectionState.yes);
    expect(restored.midtermPrepayment.value, 4200000);
    expect(restored.otherPrepaymentSelection, SelectionState.no);
  });
}
