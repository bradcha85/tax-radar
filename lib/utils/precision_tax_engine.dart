import '../models/precision_tax.dart';

class PrecisionScore {
  final int value;
  final String label;

  const PrecisionScore({required this.value, required this.label});
}

class PrecisionEstimatedItem {
  final String key;
  final String title;
  final String description;
  final int stepIndex;
  final PrecisionValueStatus status;

  const PrecisionEstimatedItem({
    required this.key,
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.status,
  });
}

class PrecisionNextAction {
  final String key;
  final String title;
  final String description;
  final int stepIndex;
  final double lostScore;

  const PrecisionNextAction({
    required this.key,
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.lostScore,
  });
}

class PrecisionTaxBreakdown {
  final int appliedYear;
  final int vatExcludedSales;
  final int businessExpenses;
  final int businessIncome;
  final int laborIncome;
  final int pensionIncome;
  final int financialIncome;
  final int otherIncome;
  final int totalIncome;
  final int personalDeduction;
  final int yellowUmbrellaDeduction;
  final int totalIncomeDeduction;
  final int taxableBase;
  final int calculatedIncomeTax;
  final int additionalTaxCredit;
  final int nationalTax;
  final int localTax;
  final int totalTax;
  final int prepaymentTotal;
  final int additionalOrRefund;

  const PrecisionTaxBreakdown({
    required this.appliedYear,
    required this.vatExcludedSales,
    required this.businessExpenses,
    required this.businessIncome,
    required this.laborIncome,
    required this.pensionIncome,
    required this.financialIncome,
    required this.otherIncome,
    required this.totalIncome,
    required this.personalDeduction,
    required this.yellowUmbrellaDeduction,
    required this.totalIncomeDeduction,
    required this.taxableBase,
    required this.calculatedIncomeTax,
    required this.additionalTaxCredit,
    required this.nationalTax,
    required this.localTax,
    required this.totalTax,
    required this.prepaymentTotal,
    required this.additionalOrRefund,
  });
}

class PrecisionTaxResult {
  final PrecisionTaxBreakdown breakdown;
  final int totalTaxMin;
  final int totalTaxMax;
  final int additionalMin;
  final int additionalMax;
  final PrecisionScore decisionScore;
  final PrecisionScore settlementScore;
  final List<PrecisionEstimatedItem> estimatedItems;
  final List<PrecisionNextAction> nextActions;
  final List<String> notices;
  final bool usesEstimatedYearConstants;

  const PrecisionTaxResult({
    required this.breakdown,
    required this.totalTaxMin,
    required this.totalTaxMax,
    required this.additionalMin,
    required this.additionalMax,
    required this.decisionScore,
    required this.settlementScore,
    required this.estimatedItems,
    required this.nextActions,
    required this.notices,
    required this.usesEstimatedYearConstants,
  });

  bool get hasEstimate =>
      estimatedItems.isNotEmpty || usesEstimatedYearConstants;
}

class _FieldValue {
  final int value;
  final PrecisionValueStatus status;
  final String key;
  final String label;
  final int stepIndex;

  const _FieldValue({
    required this.value,
    required this.status,
    required this.key,
    required this.label,
    required this.stepIndex,
  });
}

class _BusinessResolved {
  final List<_FieldValue> salesFields;
  final List<_FieldValue> expenseFields;
  final double salesFactor;
  final double expenseFactor;
  final List<PrecisionEstimatedItem> estimatedItems;

  const _BusinessResolved({
    required this.salesFields,
    required this.expenseFields,
    required this.salesFactor,
    required this.expenseFactor,
    required this.estimatedItems,
  });
}

class _CoreOutcome {
  final int vatExcludedSales;
  final int businessExpenses;
  final int businessIncome;
  final int laborIncome;
  final int pensionIncome;
  final int financialIncome;
  final int otherIncome;
  final int totalIncome;
  final int personalDeduction;
  final int yellowUmbrellaDeduction;
  final int totalIncomeDeduction;
  final int taxableBase;
  final int calculatedIncomeTax;
  final int additionalTaxCredit;
  final int nationalTax;
  final int localTax;
  final int totalTax;
  final int prepaymentTotal;
  final int additionalOrRefund;

  const _CoreOutcome({
    required this.vatExcludedSales,
    required this.businessExpenses,
    required this.businessIncome,
    required this.laborIncome,
    required this.pensionIncome,
    required this.financialIncome,
    required this.otherIncome,
    required this.totalIncome,
    required this.personalDeduction,
    required this.yellowUmbrellaDeduction,
    required this.totalIncomeDeduction,
    required this.taxableBase,
    required this.calculatedIncomeTax,
    required this.additionalTaxCredit,
    required this.nationalTax,
    required this.localTax,
    required this.totalTax,
    required this.prepaymentTotal,
    required this.additionalOrRefund,
  });
}

enum _BoundMode { base, lower, upper }

class PrecisionTaxEngine {
  PrecisionTaxEngine._();

  static const Set<int> _supportedConstantYears = {2025};

  static bool hasConstantsForYear(int year) {
    return _supportedConstantYears.contains(year);
  }

  static int resolveAppliedYear(int year) {
    if (_supportedConstantYears.contains(year)) return year;
    final candidates = _supportedConstantYears.where((item) => item <= year);
    if (candidates.isNotEmpty) {
      return candidates.reduce((a, b) => a > b ? a : b);
    }
    return _supportedConstantYears.reduce((a, b) => a < b ? a : b);
  }

  static PrecisionTaxResult calculate({
    required PrecisionTaxDraft draft,
    required String businessType,
  }) {
    final appliedYear = resolveAppliedYear(draft.taxYear);
    final usesEstimatedYearConstants = appliedYear != draft.taxYear;
    final coreBase = _calculateCore(
      draft: draft,
      businessType: businessType,
      appliedYear: appliedYear,
      boundMode: _BoundMode.base,
    );
    final coreLower = _calculateCore(
      draft: draft,
      businessType: businessType,
      appliedYear: appliedYear,
      boundMode: _BoundMode.lower,
    );
    final coreUpper = _calculateCore(
      draft: draft,
      businessType: businessType,
      appliedYear: appliedYear,
      boundMode: _BoundMode.upper,
    );

    final estimatedItems = _collectEstimatedItems(
      draft: draft,
      businessType: businessType,
    );
    final decisionScore = _decisionScore(
      draft: draft,
      businessType: businessType,
    );
    final settlementScore = _settlementScore(
      draft: draft,
      decisionScore: decisionScore.value,
    );
    final nextActions = _nextActions(
      draft: draft,
      businessType: businessType,
      decisionScore: decisionScore.value,
    );

    final notices = <String>[];
    if (usesEstimatedYearConstants) {
      notices.add('선택한 귀속연도 상수표가 없어 $appliedYear년 기준으로 예상 계산했어요.');
    }
    if (draft.hasFinancialIncome &&
        draft.financialOverTwentyMillion == SelectionState.unknown) {
      notices.add('금융소득 과세구분이 불확실해 결과 범위가 넓어질 수 있어요.');
    }
    if (coreBase.prepaymentTotal == 0) {
      notices.add('기납부가 0원이면 추가 납부/환급은 참고용이에요.');
    }

    final breakdown = PrecisionTaxBreakdown(
      appliedYear: appliedYear,
      vatExcludedSales: coreBase.vatExcludedSales,
      businessExpenses: coreBase.businessExpenses,
      businessIncome: coreBase.businessIncome,
      laborIncome: coreBase.laborIncome,
      pensionIncome: coreBase.pensionIncome,
      financialIncome: coreBase.financialIncome,
      otherIncome: coreBase.otherIncome,
      totalIncome: coreBase.totalIncome,
      personalDeduction: coreBase.personalDeduction,
      yellowUmbrellaDeduction: coreBase.yellowUmbrellaDeduction,
      totalIncomeDeduction: coreBase.totalIncomeDeduction,
      taxableBase: coreBase.taxableBase,
      calculatedIncomeTax: coreBase.calculatedIncomeTax,
      additionalTaxCredit: coreBase.additionalTaxCredit,
      nationalTax: coreBase.nationalTax,
      localTax: coreBase.localTax,
      totalTax: coreBase.totalTax,
      prepaymentTotal: coreBase.prepaymentTotal,
      additionalOrRefund: coreBase.additionalOrRefund,
    );

    return PrecisionTaxResult(
      breakdown: breakdown,
      totalTaxMin: coreLower.totalTax < coreUpper.totalTax
          ? coreLower.totalTax
          : coreUpper.totalTax,
      totalTaxMax: coreLower.totalTax > coreUpper.totalTax
          ? coreLower.totalTax
          : coreUpper.totalTax,
      additionalMin: coreLower.additionalOrRefund < coreUpper.additionalOrRefund
          ? coreLower.additionalOrRefund
          : coreUpper.additionalOrRefund,
      additionalMax: coreLower.additionalOrRefund > coreUpper.additionalOrRefund
          ? coreLower.additionalOrRefund
          : coreUpper.additionalOrRefund,
      decisionScore: decisionScore,
      settlementScore: settlementScore,
      estimatedItems: estimatedItems,
      nextActions: nextActions,
      notices: notices,
      usesEstimatedYearConstants: usesEstimatedYearConstants,
    );
  }

  static _CoreOutcome _calculateCore({
    required PrecisionTaxDraft draft,
    required String businessType,
    required int appliedYear,
    required _BoundMode boundMode,
  }) {
    final businessResolved = _resolveBusiness(
      draft: draft,
      businessType: businessType,
    );
    final forLower = boundMode == _BoundMode.lower;
    final forUpper = boundMode == _BoundMode.upper;
    int resolveField(_FieldValue field, {required bool increasesResult}) {
      if (boundMode == _BoundMode.base) return field.value;
      return _applyUncertainty(
        value: field.value,
        status: field.status,
        forLowerBound: forLower,
        increasesResult: increasesResult,
      );
    }

    final vatExcludedSales = businessResolved.salesFields.fold<int>(
      0,
      (sum, field) => sum + resolveField(field, increasesResult: true),
    );
    final businessExpenses = businessResolved.expenseFields.fold<int>(
      0,
      (sum, field) => sum + resolveField(field, increasesResult: false),
    );
    final businessIncome = (vatExcludedSales - businessExpenses).clamp(
      0,
      1 << 60,
    );

    final laborIncome = draft.hasLaborIncome
        ? _resolveIncomeAmount(
            field: draft.laborIncome.incomeAmount,
            boundMode: boundMode,
          )
        : 0;
    final pensionIncome = draft.hasPensionIncome
        ? _resolveIncomeAmount(
            field: draft.pensionIncome.incomeAmount,
            boundMode: boundMode,
          )
        : 0;
    final financialIncome = draft.hasFinancialIncome
        ? _resolveIncomeAmount(
            field: draft.financialIncome.incomeAmount,
            boundMode: boundMode,
          )
        : 0;
    final otherIncome = draft.hasOtherIncome
        ? _resolveIncomeAmount(
            field: draft.otherIncome.incomeAmount,
            boundMode: boundMode,
          )
        : 0;

    final totalIncome =
        (businessIncome +
                laborIncome +
                pensionIncome +
                financialIncome +
                otherIncome)
            .clamp(0, 1 << 60);

    final spouseCount = switch (draft.spouseSelection) {
      SelectionState.yes => const NumericField(
        value: 1,
        status: PrecisionValueStatus.complete,
      ),
      SelectionState.no => const NumericField(
        value: 0,
        status: PrecisionValueStatus.complete,
      ),
      SelectionState.unknown => const NumericField(
        value: 0,
        status: PrecisionValueStatus.estimatedUser,
      ),
      SelectionState.unset => NumericField.missing,
    };
    final childrenCount = draft.childrenCount;
    final parentsCount = draft.parentsCount;

    int resolveDeductionCount(NumericField field) {
      if (boundMode == _BoundMode.base) return field.safeValue;
      return _applyUncertainty(
        value: field.safeValue,
        status: field.status,
        forLowerBound: forLower,
        increasesResult: false,
      );
    }

    final dependentCount =
        1 +
        resolveDeductionCount(spouseCount) +
        resolveDeductionCount(childrenCount) +
        resolveDeductionCount(parentsCount);
    final personalDeduction = dependentCount * 1500000;

    final yellowUmbrellaDeduction = _resolveYellowUmbrellaDeduction(
      selection: draft.yellowUmbrellaSelection,
      paymentField: draft.yellowUmbrellaAnnualPayment,
      businessIncome: businessIncome,
      boundMode: boundMode,
    );
    final totalIncomeDeduction = personalDeduction + yellowUmbrellaDeduction;
    final taxableBase = (totalIncome - totalIncomeDeduction).clamp(0, 1 << 60);

    final calculatedIncomeTax = _truncate10(
      _applyTaxBracket(taxableBase, appliedYear),
    );
    final additionalTaxCredit = _resolveAdditionalTaxCredit(
      field: draft.additionalTaxCredit,
      boundMode: boundMode,
    );
    final nationalTax = _truncate10(
      (calculatedIncomeTax - additionalTaxCredit).clamp(0, 1 << 60),
    );
    final localTax = _truncate10((nationalTax * 0.1).floor());
    final totalTax = nationalTax + localTax;

    final prepaymentTotal = _resolvePrepaymentTotal(
      draft: draft,
      boundMode: boundMode,
      forLowerResult: forLower,
      forUpperResult: forUpper,
    );
    final additionalOrRefund = totalTax - prepaymentTotal;

    return _CoreOutcome(
      vatExcludedSales: vatExcludedSales,
      businessExpenses: businessExpenses,
      businessIncome: businessIncome,
      laborIncome: laborIncome,
      pensionIncome: pensionIncome,
      financialIncome: financialIncome,
      otherIncome: otherIncome,
      totalIncome: totalIncome,
      personalDeduction: personalDeduction,
      yellowUmbrellaDeduction: yellowUmbrellaDeduction,
      totalIncomeDeduction: totalIncomeDeduction,
      taxableBase: taxableBase,
      calculatedIncomeTax: calculatedIncomeTax,
      additionalTaxCredit: additionalTaxCredit,
      nationalTax: nationalTax,
      localTax: localTax,
      totalTax: totalTax,
      prepaymentTotal: prepaymentTotal,
      additionalOrRefund: additionalOrRefund,
    );
  }

  static _BusinessResolved _resolveBusiness({
    required PrecisionTaxDraft draft,
    required String businessType,
  }) {
    final estimatedItems = <PrecisionEstimatedItem>[];
    final salesFields = <_FieldValue>[];
    final expenseFields = <_FieldValue>[];

    if (draft.businessInputMode == BusinessInputMode.annual) {
      final normalizedSales = _normalizeSales(
        value: draft.annualSales.safeValue,
        vatChoice: draft.annualSalesVatMode,
      );
      var salesStatus = draft.annualSales.status;
      if (draft.annualSalesVatMode == VatInclusionChoice.unknown &&
          draft.annualSales.hasValue &&
          salesStatus == PrecisionValueStatus.complete) {
        salesStatus = PrecisionValueStatus.estimatedUser;
      }
      salesFields.add(
        _FieldValue(
          key: 'business_sales_annual',
          label: '사업소득 연간 매출',
          value: normalizedSales,
          status: salesStatus,
          stepIndex: 1,
        ),
      );
      if (draft.bookkeeping) {
        expenseFields.add(
          _FieldValue(
            key: 'business_expense_annual',
            label: '사업소득 연간 경비',
            value: draft.annualExpenses.safeValue,
            status: draft.annualExpenses.status,
            stepIndex: 1,
          ),
        );
      } else {
        final simpleRate = _simpleExpenseRateByBusinessType(businessType);
        expenseFields.add(
          _FieldValue(
            key: 'business_expense_simple',
            label: '단순경비율 경비',
            value: (normalizedSales * simpleRate).round(),
            status: PrecisionValueStatus.estimatedIndustry,
            stepIndex: 1,
          ),
        );
      }
    } else {
      final monthly = draft.monthlyBusinessInputs.toList()
        ..sort((a, b) => a.month.compareTo(b.month));

      final explicitSales = monthly
          .where((item) => item.sales.hasValue)
          .toList();
      final explicitSalesAvg = explicitSales.isNotEmpty
          ? explicitSales.fold<int>(
                  0,
                  (sum, item) => sum + item.sales.safeValue,
                ) ~/
                explicitSales.length
          : 0;
      final effectiveSales = <_FieldValue>[];
      int salesEstimatedUserCount = 0;
      int salesEstimatedIndustryCount = 0;

      for (final month in monthly) {
        NumericField field = month.sales;
        if (!field.hasValue) {
          if (draft.fillMissingMonths) {
            if (explicitSales.isNotEmpty) {
              field = NumericField(
                value: explicitSalesAvg,
                status: PrecisionValueStatus.estimatedUser,
              );
              salesEstimatedUserCount++;
            } else {
              field = const NumericField(
                value: 0,
                status: PrecisionValueStatus.estimatedIndustry,
              );
              salesEstimatedIndustryCount++;
            }
          } else {
            field = const NumericField(
              value: 0,
              status: PrecisionValueStatus.missing,
            );
          }
        }

        var status = field.status;
        if (draft.annualSalesVatMode == VatInclusionChoice.unknown &&
            status == PrecisionValueStatus.complete &&
            field.hasValue) {
          status = PrecisionValueStatus.estimatedUser;
        }
        effectiveSales.add(
          _FieldValue(
            key: 'business_sales_m${month.month}',
            label: '${month.month}월 사업소득 매출',
            value: _normalizeSales(
              value: field.safeValue,
              vatChoice: draft.annualSalesVatMode,
            ),
            status: status,
            stepIndex: 1,
          ),
        );
      }
      salesFields.addAll(effectiveSales);
      if (salesEstimatedUserCount > 0) {
        estimatedItems.add(
          PrecisionEstimatedItem(
            key: 'business_sales_missing_user',
            title: '사업소득 매출 누락월',
            description: '$salesEstimatedUserCount개월을 같은 연도 평균으로 채웠어요.',
            stepIndex: 1,
            status: PrecisionValueStatus.estimatedUser,
          ),
        );
      }
      if (salesEstimatedIndustryCount > 0) {
        estimatedItems.add(
          PrecisionEstimatedItem(
            key: 'business_sales_missing_industry',
            title: '사업소득 매출 누락월',
            description: '$salesEstimatedIndustryCount개월을 업종 추정으로 채웠어요.',
            stepIndex: 1,
            status: PrecisionValueStatus.estimatedIndustry,
          ),
        );
      }

      if (draft.bookkeeping) {
        final explicitExpenses = monthly
            .where((item) => item.expenses.hasValue)
            .toList();
        final explicitExpenseAvg = explicitExpenses.isNotEmpty
            ? explicitExpenses.fold<int>(
                    0,
                    (sum, item) => sum + item.expenses.safeValue,
                  ) ~/
                  explicitExpenses.length
            : 0;
        int expenseEstimatedUserCount = 0;
        int expenseEstimatedIndustryCount = 0;

        for (final month in monthly) {
          NumericField field = month.expenses;
          if (!field.hasValue) {
            if (draft.fillMissingMonths) {
              if (explicitExpenses.isNotEmpty) {
                field = NumericField(
                  value: explicitExpenseAvg,
                  status: PrecisionValueStatus.estimatedUser,
                );
                expenseEstimatedUserCount++;
              } else {
                final monthlySales = effectiveSales
                    .firstWhere(
                      (item) => item.key == 'business_sales_m${month.month}',
                    )
                    .value;
                field = NumericField(
                  value: (monthlySales * _industryExpenseRatio(businessType))
                      .round(),
                  status: PrecisionValueStatus.estimatedIndustry,
                );
                expenseEstimatedIndustryCount++;
              }
            } else {
              field = const NumericField(
                value: 0,
                status: PrecisionValueStatus.missing,
              );
            }
          }
          expenseFields.add(
            _FieldValue(
              key: 'business_expense_m${month.month}',
              label: '${month.month}월 사업소득 경비',
              value: field.safeValue,
              status: field.status,
              stepIndex: 1,
            ),
          );
        }

        if (expenseEstimatedUserCount > 0) {
          estimatedItems.add(
            PrecisionEstimatedItem(
              key: 'business_expense_missing_user',
              title: '사업소득 경비 누락월',
              description: '$expenseEstimatedUserCount개월을 같은 연도 평균으로 채웠어요.',
              stepIndex: 1,
              status: PrecisionValueStatus.estimatedUser,
            ),
          );
        }
        if (expenseEstimatedIndustryCount > 0) {
          estimatedItems.add(
            PrecisionEstimatedItem(
              key: 'business_expense_missing_industry',
              title: '사업소득 경비 누락월',
              description: '$expenseEstimatedIndustryCount개월을 업종 비율로 채웠어요.',
              stepIndex: 1,
              status: PrecisionValueStatus.estimatedIndustry,
            ),
          );
        }
      } else {
        for (final month in monthly) {
          final monthlySales = effectiveSales
              .firstWhere(
                (item) => item.key == 'business_sales_m${month.month}',
              )
              .value;
          expenseFields.add(
            _FieldValue(
              key: 'business_expense_simple_m${month.month}',
              label: '${month.month}월 단순경비율 경비',
              value:
                  (monthlySales *
                          _simpleExpenseRateByBusinessType(businessType))
                      .round(),
              status: PrecisionValueStatus.estimatedIndustry,
              stepIndex: 1,
            ),
          );
        }
      }
    }

    final salesFactor = salesFields.isEmpty
        ? 0.0
        : salesFields.fold<double>(
                0,
                (sum, field) => sum + field.status.scoreFactor,
              ) /
              salesFields.length;
    final expenseFactor = expenseFields.isEmpty
        ? 0.0
        : expenseFields.fold<double>(
                0,
                (sum, field) => sum + field.status.scoreFactor,
              ) /
              expenseFields.length;

    return _BusinessResolved(
      salesFields: salesFields,
      expenseFields: expenseFields,
      salesFactor: salesFactor,
      expenseFactor: expenseFactor,
      estimatedItems: estimatedItems,
    );
  }

  static List<PrecisionEstimatedItem> _collectEstimatedItems({
    required PrecisionTaxDraft draft,
    required String businessType,
  }) {
    final items = <PrecisionEstimatedItem>[];
    final business = _resolveBusiness(draft: draft, businessType: businessType);
    items.addAll(business.estimatedItems);

    void addFieldItem({
      required String key,
      required String title,
      required String description,
      required NumericField field,
      required int stepIndex,
    }) {
      if (!field.status.isEstimated) return;
      items.add(
        PrecisionEstimatedItem(
          key: key,
          title: title,
          description: description,
          stepIndex: stepIndex,
          status: field.status,
        ),
      );
    }

    if (draft.annualSalesVatMode == VatInclusionChoice.unknown &&
        (draft.businessInputMode == BusinessInputMode.annual
            ? draft.annualSales.hasValue
            : true)) {
      items.add(
        const PrecisionEstimatedItem(
          key: 'business_sales_vat_unknown',
          title: 'VAT 포함 여부',
          description: 'VAT 포함으로 가정해 계산했어요.',
          stepIndex: 1,
          status: PrecisionValueStatus.estimatedUser,
        ),
      );
    }

    if (draft.hasLaborIncome) {
      addFieldItem(
        key: 'income_labor',
        title: '근로소득',
        description: '근로소득을 추정값으로 반영했어요.',
        field: draft.laborIncome.incomeAmount,
        stepIndex: 1,
      );
      addFieldItem(
        key: 'withholding_labor',
        title: '근로 원천징수',
        description: '근로 원천징수를 추정 0 또는 추정값으로 반영했어요.',
        field: draft.laborIncome.withholdingTax,
        stepIndex: 3,
      );
    }
    if (draft.hasPensionIncome) {
      addFieldItem(
        key: 'income_pension',
        title: '연금소득',
        description: '연금소득을 추정값으로 반영했어요.',
        field: draft.pensionIncome.incomeAmount,
        stepIndex: 1,
      );
      addFieldItem(
        key: 'withholding_pension',
        title: '연금 원천징수',
        description: '연금 원천징수를 추정 0 또는 추정값으로 반영했어요.',
        field: draft.pensionIncome.withholdingTax,
        stepIndex: 3,
      );
    }
    if (draft.hasFinancialIncome) {
      addFieldItem(
        key: 'income_financial',
        title: '금융소득',
        description: '금융소득을 추정값으로 반영했어요.',
        field: draft.financialIncome.incomeAmount,
        stepIndex: 1,
      );
      addFieldItem(
        key: 'withholding_financial',
        title: '금융 원천징수',
        description: '금융 원천징수를 추정 0 또는 추정값으로 반영했어요.',
        field: draft.financialIncome.withholdingTax,
        stepIndex: 3,
      );
    }
    if (draft.hasOtherIncome) {
      addFieldItem(
        key: 'income_other',
        title: '기타소득',
        description: '기타소득을 추정값으로 반영했어요.',
        field: draft.otherIncome.incomeAmount,
        stepIndex: 1,
      );
      addFieldItem(
        key: 'withholding_other',
        title: '기타 원천징수',
        description: '기타 원천징수를 추정 0 또는 추정값으로 반영했어요.',
        field: draft.otherIncome.withholdingTax,
        stepIndex: 3,
      );
    }

    if (draft.spouseSelection == SelectionState.unknown) {
      items.add(
        const PrecisionEstimatedItem(
          key: 'deduction_spouse',
          title: '배우자 인적공제',
          description: '모름 선택으로 보수적(0명) 처리했어요.',
          stepIndex: 2,
          status: PrecisionValueStatus.estimatedUser,
        ),
      );
    }
    addFieldItem(
      key: 'deduction_children',
      title: '자녀 인적공제',
      description: '자녀 수를 추정값으로 처리했어요.',
      field: draft.childrenCount,
      stepIndex: 2,
    );
    addFieldItem(
      key: 'deduction_parents',
      title: '부모 인적공제',
      description: '부모 부양 수를 추정값으로 처리했어요.',
      field: draft.parentsCount,
      stepIndex: 2,
    );

    if (draft.yellowUmbrellaSelection == SelectionState.unknown) {
      items.add(
        const PrecisionEstimatedItem(
          key: 'yellow_unknown',
          title: '노란우산',
          description: '모름 선택으로 0원(추정) 처리했어요.',
          stepIndex: 2,
          status: PrecisionValueStatus.estimatedZero,
        ),
      );
    }
    addFieldItem(
      key: 'yellow_payment',
      title: '노란우산 납입액',
      description: '노란우산 납입액을 추정값으로 처리했어요.',
      field: draft.yellowUmbrellaAnnualPayment,
      stepIndex: 2,
    );
    addFieldItem(
      key: 'tax_credit',
      title: '추가 세액공제',
      description: '세액공제를 추정값으로 처리했어요.',
      field: draft.additionalTaxCredit,
      stepIndex: 2,
    );

    if (draft.midtermPrepaymentSelection == SelectionState.unknown) {
      items.add(
        const PrecisionEstimatedItem(
          key: 'prepay_midterm_unknown',
          title: '중간예납',
          description: '중간예납을 추정 0으로 처리했어요.',
          stepIndex: 3,
          status: PrecisionValueStatus.estimatedZero,
        ),
      );
    }
    if (draft.otherPrepaymentSelection == SelectionState.unknown) {
      items.add(
        const PrecisionEstimatedItem(
          key: 'prepay_other_unknown',
          title: '기타 기납부',
          description: '기타 기납부를 추정 0으로 처리했어요.',
          stepIndex: 3,
          status: PrecisionValueStatus.estimatedZero,
        ),
      );
    }

    return items;
  }

  static PrecisionScore _decisionScore({
    required PrecisionTaxDraft draft,
    required String businessType,
  }) {
    final business = _resolveBusiness(draft: draft, businessType: businessType);
    final salesFactor = business.salesFactor;
    final expenseFactor = business.expenseFactor;

    final enabledOptionalIncomes = <IncomeCategoryInput>[];
    if (draft.hasLaborIncome) enabledOptionalIncomes.add(draft.laborIncome);
    if (draft.hasPensionIncome) enabledOptionalIncomes.add(draft.pensionIncome);
    if (draft.hasFinancialIncome) {
      enabledOptionalIncomes.add(draft.financialIncome);
    }
    if (draft.hasOtherIncome) enabledOptionalIncomes.add(draft.otherIncome);

    final businessAverageFactor = (salesFactor + expenseFactor) / 2;
    final optionalIncomeFactor = enabledOptionalIncomes.isEmpty
        ? businessAverageFactor
        : enabledOptionalIncomes.fold<double>(
                0,
                (sum, item) => sum + item.incomeAmount.status.scoreFactor,
              ) /
              enabledOptionalIncomes.length;

    final spouseFactor = draft.spouseSelection.status.scoreFactor;
    final childrenFactor = draft.childrenCount.status.scoreFactor;
    final parentsFactor = draft.parentsCount.status.scoreFactor;
    final personalDeductionFactor =
        (spouseFactor + childrenFactor + parentsFactor) / 3;

    final yellowFactor = switch (draft.yellowUmbrellaSelection) {
      SelectionState.no => 1.0,
      SelectionState.yes =>
        draft.yellowUmbrellaAnnualPayment.status.scoreFactor,
      SelectionState.unknown => 0.7,
      SelectionState.unset => 0.0,
    };
    final extraCreditFactor = draft.additionalTaxCredit.status.scoreFactor;
    final deductionExtraFactor = (yellowFactor + extraCreditFactor) / 2;

    final score =
        (salesFactor * 30) +
        (expenseFactor * 30) +
        (optionalIncomeFactor * 15) +
        (personalDeductionFactor * 10) +
        (deductionExtraFactor * 15);

    final clamped = score.round().clamp(0, 100);
    return PrecisionScore(value: clamped, label: _scoreLabel(clamped));
  }

  static PrecisionScore _settlementScore({
    required PrecisionTaxDraft draft,
    required int decisionScore,
  }) {
    final withholdingFactors = <double>[];
    if (draft.hasLaborIncome) {
      withholdingFactors.add(
        draft.laborIncome.withholdingTax.status == PrecisionValueStatus.complete
            ? 1
            : 0,
      );
    }
    if (draft.hasPensionIncome) {
      withholdingFactors.add(
        draft.pensionIncome.withholdingTax.status ==
                PrecisionValueStatus.complete
            ? 1
            : 0,
      );
    }
    if (draft.hasFinancialIncome) {
      withholdingFactors.add(
        draft.financialIncome.withholdingTax.status ==
                PrecisionValueStatus.complete
            ? 1
            : 0,
      );
    }
    if (draft.hasOtherIncome) {
      withholdingFactors.add(
        draft.otherIncome.withholdingTax.status == PrecisionValueStatus.complete
            ? 1
            : 0,
      );
    }

    final withholdingScore = withholdingFactors.isEmpty
        ? 80.0
        : (withholdingFactors.reduce((a, b) => a + b) /
                  withholdingFactors.length) *
              80;

    final midtermFactor = _prepaymentSelectionFactor(
      selection: draft.midtermPrepaymentSelection,
      field: draft.midtermPrepayment,
    );
    final otherFactor = _prepaymentSelectionFactor(
      selection: draft.otherPrepaymentSelection,
      field: draft.otherPrepayment,
    );
    final prepaymentScore =
        withholdingScore + (midtermFactor * 10) + (otherFactor * 10);

    final settlement = (decisionScore * 0.70) + (prepaymentScore * 0.30);
    final rounded = settlement.round().clamp(0, 100);
    return PrecisionScore(value: rounded, label: _scoreLabel(rounded));
  }

  static List<PrecisionNextAction> _nextActions({
    required PrecisionTaxDraft draft,
    required String businessType,
    required int decisionScore,
  }) {
    final business = _resolveBusiness(draft: draft, businessType: businessType);
    final salesFactor = business.salesFactor;
    final expenseFactor = business.expenseFactor;
    final businessAverageFactor = (salesFactor + expenseFactor) / 2;

    final enabledOptionalIncomes = <IncomeCategoryInput>[];
    if (draft.hasLaborIncome) enabledOptionalIncomes.add(draft.laborIncome);
    if (draft.hasPensionIncome) enabledOptionalIncomes.add(draft.pensionIncome);
    if (draft.hasFinancialIncome) {
      enabledOptionalIncomes.add(draft.financialIncome);
    }
    if (draft.hasOtherIncome) enabledOptionalIncomes.add(draft.otherIncome);
    final optionalIncomeFactor = enabledOptionalIncomes.isEmpty
        ? businessAverageFactor
        : enabledOptionalIncomes.fold<double>(
                0,
                (sum, item) => sum + item.incomeAmount.status.scoreFactor,
              ) /
              enabledOptionalIncomes.length;

    final spouseFactor = draft.spouseSelection.status.scoreFactor;
    final childrenFactor = draft.childrenCount.status.scoreFactor;
    final parentsFactor = draft.parentsCount.status.scoreFactor;
    final personalFactor = (spouseFactor + childrenFactor + parentsFactor) / 3;

    final yellowFactor = switch (draft.yellowUmbrellaSelection) {
      SelectionState.no => 1.0,
      SelectionState.yes =>
        draft.yellowUmbrellaAnnualPayment.status.scoreFactor,
      SelectionState.unknown => 0.7,
      SelectionState.unset => 0.0,
    };
    final extraCreditFactor = draft.additionalTaxCredit.status.scoreFactor;
    final extraDeductionFactor = (yellowFactor + extraCreditFactor) / 2;

    final withholdingFactors = <double>[];
    if (draft.hasLaborIncome) {
      withholdingFactors.add(
        draft.laborIncome.withholdingTax.status == PrecisionValueStatus.complete
            ? 1
            : 0,
      );
    }
    if (draft.hasPensionIncome) {
      withholdingFactors.add(
        draft.pensionIncome.withholdingTax.status ==
                PrecisionValueStatus.complete
            ? 1
            : 0,
      );
    }
    if (draft.hasFinancialIncome) {
      withholdingFactors.add(
        draft.financialIncome.withholdingTax.status ==
                PrecisionValueStatus.complete
            ? 1
            : 0,
      );
    }
    if (draft.hasOtherIncome) {
      withholdingFactors.add(
        draft.otherIncome.withholdingTax.status == PrecisionValueStatus.complete
            ? 1
            : 0,
      );
    }
    final withholdingFactor = withholdingFactors.isEmpty
        ? 1.0
        : (withholdingFactors.reduce((a, b) => a + b) /
              withholdingFactors.length);
    final midtermFactor = _prepaymentSelectionFactor(
      selection: draft.midtermPrepaymentSelection,
      field: draft.midtermPrepayment,
    );
    final otherFactor = _prepaymentSelectionFactor(
      selection: draft.otherPrepaymentSelection,
      field: draft.otherPrepayment,
    );

    final candidates = <PrecisionNextAction>[
      PrecisionNextAction(
        key: 'loss_sales',
        title: '사업 매출 보완',
        description: '매출이 비면 결정세액이 크게 달라져요.',
        stepIndex: 1,
        lostScore: 30 * (1 - salesFactor),
      ),
      PrecisionNextAction(
        key: 'loss_expenses',
        title: '사업 경비 보완',
        description: '경비가 비면 과세표준 오차가 커져요.',
        stepIndex: 1,
        lostScore: 30 * (1 - expenseFactor),
      ),
      PrecisionNextAction(
        key: 'loss_optional_income',
        title: 'N잡 소득 보완',
        description: '체크한 소득을 입력해야 합산세액이 정확해져요.',
        stepIndex: 1,
        lostScore: 15 * (1 - optionalIncomeFactor),
      ),
      PrecisionNextAction(
        key: 'loss_personal',
        title: '인적공제 확인',
        description: '가족 공제는 세금 절감에 직접 영향이 있어요.',
        stepIndex: 2,
        lostScore: 10 * (1 - personalFactor),
      ),
      PrecisionNextAction(
        key: 'loss_deduction_extra',
        title: '공제 항목 확인',
        description: '노란우산/세액공제 입력 시 세금이 줄 수 있어요.',
        stepIndex: 2,
        lostScore: 15 * (1 - extraDeductionFactor),
      ),
      PrecisionNextAction(
        key: 'loss_withholding',
        title: '원천징수 입력',
        description: '기납부가 비면 추가 납부/환급은 참고용이 돼요.',
        stepIndex: 3,
        lostScore: 24 * (1 - withholdingFactor),
      ),
      PrecisionNextAction(
        key: 'loss_midterm',
        title: '중간예납 확인',
        description: '중간예납 누락 시 추가/환급 계산이 흔들려요.',
        stepIndex: 3,
        lostScore: 3 * (1 - midtermFactor),
      ),
      PrecisionNextAction(
        key: 'loss_other_prepay',
        title: '기타 기납부 확인',
        description: '기타 기납부 누락분이 있으면 결과가 달라져요.',
        stepIndex: 3,
        lostScore: 3 * (1 - otherFactor),
      ),
      PrecisionNextAction(
        key: 'loss_overall_decision',
        title: '결정세액 정밀도 개선',
        description: '결정세액 정밀도가 낮아 결과 오차 가능성이 커요.',
        stepIndex: 1,
        lostScore: 70 * ((100 - decisionScore) / 100),
      ),
    ];

    final filtered = candidates.where((item) => item.lostScore > 0.01).toList()
      ..sort((a, b) => b.lostScore.compareTo(a.lostScore));
    return filtered.take(3).toList();
  }

  static int _resolveIncomeAmount({
    required NumericField field,
    required _BoundMode boundMode,
  }) {
    if (boundMode == _BoundMode.base) return field.safeValue;
    return _applyUncertainty(
      value: field.safeValue,
      status: field.status,
      forLowerBound: boundMode == _BoundMode.lower,
      increasesResult: true,
    );
  }

  static int _resolveAdditionalTaxCredit({
    required NumericField field,
    required _BoundMode boundMode,
  }) {
    final base = field.safeValue;
    final resolved = boundMode == _BoundMode.base
        ? base
        : _applyUncertainty(
            value: base,
            status: field.status,
            forLowerBound: boundMode == _BoundMode.lower,
            increasesResult: false,
          );
    return _truncate10(resolved);
  }

  static int _resolveYellowUmbrellaDeduction({
    required SelectionState selection,
    required NumericField paymentField,
    required int businessIncome,
    required _BoundMode boundMode,
  }) {
    if (selection == SelectionState.no || selection == SelectionState.unset) {
      return 0;
    }
    if (selection == SelectionState.unknown) {
      return 0;
    }

    final payment = boundMode == _BoundMode.base
        ? paymentField.safeValue
        : _applyUncertainty(
            value: paymentField.safeValue,
            status: paymentField.status,
            forLowerBound: boundMode == _BoundMode.lower,
            increasesResult: false,
          );

    final limit = _yellowUmbrellaLimit(businessIncome);
    return _truncate10(payment < limit ? payment : limit);
  }

  static int _resolvePrepaymentTotal({
    required PrecisionTaxDraft draft,
    required _BoundMode boundMode,
    required bool forLowerResult,
    required bool forUpperResult,
  }) {
    int resolveWithholding(IncomeCategoryInput category, bool enabled) {
      if (!enabled) return 0;
      final field = category.withholdingTax;
      if (boundMode == _BoundMode.base) {
        return field.safeValue;
      }
      return _applyUncertainty(
        value: field.safeValue,
        status: field.status,
        forLowerBound: forLowerResult,
        increasesResult: false,
      );
    }

    int resolveSelectionAmount({
      required SelectionState selection,
      required NumericField field,
    }) {
      final normalized = switch (selection) {
        SelectionState.yes => field,
        SelectionState.no => const NumericField(
          value: 0,
          status: PrecisionValueStatus.complete,
        ),
        SelectionState.unknown => const NumericField(
          value: 0,
          status: PrecisionValueStatus.estimatedZero,
        ),
        SelectionState.unset => NumericField.missing,
      };

      if (boundMode == _BoundMode.base) {
        return normalized.safeValue;
      }
      return _applyUncertainty(
        value: normalized.safeValue,
        status: normalized.status,
        forLowerBound: forLowerResult,
        increasesResult: false,
      );
    }

    final labor = resolveWithholding(draft.laborIncome, draft.hasLaborIncome);
    final pension = resolveWithholding(
      draft.pensionIncome,
      draft.hasPensionIncome,
    );
    final financial = resolveWithholding(
      draft.financialIncome,
      draft.hasFinancialIncome,
    );
    final other = resolveWithholding(draft.otherIncome, draft.hasOtherIncome);
    final midterm = resolveSelectionAmount(
      selection: draft.midtermPrepaymentSelection,
      field: draft.midtermPrepayment,
    );
    final otherPrepayment = resolveSelectionAmount(
      selection: draft.otherPrepaymentSelection,
      field: draft.otherPrepayment,
    );

    return _truncate10(
      labor + pension + financial + other + midterm + otherPrepayment,
    );
  }

  static int _applyTaxBracket(int taxBase, int year) {
    final applied = resolveAppliedYear(year);
    if (applied == 2025) {
      if (taxBase <= 14000000) {
        return (taxBase * 0.06).floor();
      }
      if (taxBase <= 50000000) {
        return (taxBase * 0.15 - 1260000).floor();
      }
      if (taxBase <= 88000000) {
        return (taxBase * 0.24 - 5760000).floor();
      }
      if (taxBase <= 150000000) {
        return (taxBase * 0.35 - 15440000).floor();
      }
      if (taxBase <= 300000000) {
        return (taxBase * 0.38 - 19940000).floor();
      }
      if (taxBase <= 500000000) {
        return (taxBase * 0.40 - 25940000).floor();
      }
      if (taxBase <= 1000000000) {
        return (taxBase * 0.42 - 35940000).floor();
      }
      return (taxBase * 0.45 - 65940000).floor();
    }
    return _applyTaxBracket(taxBase, 2025);
  }

  static int _yellowUmbrellaLimit(int businessIncome) {
    if (businessIncome <= 40000000) return 6000000;
    if (businessIncome <= 60000000) return 5000000;
    if (businessIncome <= 100000000) return 4000000;
    return 2000000;
  }

  static int _normalizeSales({
    required int value,
    required VatInclusionChoice vatChoice,
  }) {
    if (value <= 0) return 0;
    switch (vatChoice) {
      case VatInclusionChoice.excluded:
        return value;
      case VatInclusionChoice.included:
      case VatInclusionChoice.unknown:
        return (value / 1.1).round();
    }
  }

  static int _applyUncertainty({
    required int value,
    required PrecisionValueStatus status,
    required bool forLowerBound,
    required bool increasesResult,
  }) {
    final percent = status.rangePercent;
    if (value <= 0 || percent <= 0) return value;
    final down = (value * (1 - percent)).round();
    final up = (value * (1 + percent)).round();

    if (forLowerBound) {
      return increasesResult ? down : up;
    }
    return increasesResult ? up : down;
  }

  static int _truncate10(int value) {
    if (value >= 0) {
      return (value ~/ 10) * 10;
    }
    final absValue = value.abs();
    return -((absValue ~/ 10) * 10);
  }

  static double _industryExpenseRatio(String businessType) {
    switch (businessType) {
      case 'restaurant':
        return 0.90;
      case 'cafe':
        return 0.88;
      default:
        return 0.85;
    }
  }

  static double _simpleExpenseRateByBusinessType(String businessType) {
    switch (businessType) {
      case 'restaurant':
        return 0.897;
      case 'cafe':
        return 0.878;
      default:
        return 0.897;
    }
  }

  static String _scoreLabel(int score) {
    if (score >= 90) return '신고급';
    if (score >= 70) return '좋아요';
    if (score >= 50) return '보통';
    return '낮음';
  }

  static double _prepaymentSelectionFactor({
    required SelectionState selection,
    required NumericField field,
  }) {
    switch (selection) {
      case SelectionState.no:
        return 1.0;
      case SelectionState.yes:
        return field.status == PrecisionValueStatus.complete ? 1.0 : 0.0;
      case SelectionState.unknown:
      case SelectionState.unset:
        return 0.0;
    }
  }
}
