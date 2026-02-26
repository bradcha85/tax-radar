import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/precision_tax.dart';
import '../../providers/business_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../utils/precision_tax_engine.dart';
import '../../widgets/notion_card.dart';
import '../../widgets/term_help_header.dart';
import '../../widgets/glossary_help_text.dart';

enum _IncomeKind { labor, pension, financial, other }

class PrecisionTaxScreen extends StatefulWidget {
  const PrecisionTaxScreen({super.key});

  @override
  State<PrecisionTaxScreen> createState() => _PrecisionTaxScreenState();
}

class _PrecisionTaxScreenState extends State<PrecisionTaxScreen> {
  final Map<String, TextEditingController> _controllers = {};
  int _currentStep = 0;
  bool _isInitialized = false;
  late PrecisionTaxDraft _draft;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    final provider = context.read<BusinessProvider>();
    _draft = provider.precisionTaxDraft;
    _isInitialized = true;

    final migrated = _migrateLegacyIndustryExpenseEstimate(
      draft: _draft,
      businessType: provider.business.businessType,
    );
    if (!identical(migrated, _draft)) {
      _draft = migrated;
      provider.updatePrecisionTaxDraft(migrated);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Layout: StepIndicator (top) + ScrollableContent (middle) + BottomNav (bottom)
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final result = PrecisionTaxEngine.calculate(
      draft: _draft,
      businessType: provider.business.businessType,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '정밀 종소세',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: () => context.push('/glossary'),
            child: Text(
              '용어 사전',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: _buildCurrentStepContent(provider, result),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    const labels = ['시작', '소득', '공제', '기납부', '결과'];

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(labels.length, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive || isCompleted
                                ? AppColors.primary
                                : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (index < labels.length - 1) const SizedBox(width: 4),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Step Label
          Text(
            '${_currentStep + 1}. ${labels[_currentStep]}',
            style: AppTypography.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(
    BusinessProvider provider,
    PrecisionTaxResult result,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildStep0(result);
      case 1:
        return _buildStep1(provider.business.businessType);
      case 2:
        return _buildStep2(result);
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4(result);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav() {
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == 4;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  textStyle: AppTypography.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: isFirst
                    ? () => context.pop()
                    : () => setState(() => _currentStep -= 1),
                child: Text(isFirst ? '닫기' : '이전'),
              ),
            ),
          ),
          if (!isLast) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTypography.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textHint,
                  ),
                  onPressed: _canContinueStep(_currentStep)
                      ? () {
                          if (_currentStep >= 4) return;
                          setState(() => _currentStep += 1);
                        }
                      : null,
                  child: Text(_currentStep == 3 ? '결과 보기' : '다음'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 0 · 시작
  // ---------------------------------------------------------------------------

  Widget _buildStep0(PrecisionTaxResult result) {
    final now = DateTime.now();
    final lastYear = now.year - 1;
    final thisYear = now.year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotionCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TermHelpHeader(title: '귀속연도 선택', termId: 'T21'),
              const SizedBox(height: 16),
              _buildNotionChips(
                options: [
                  _ChipOption('작년($lastYear, 신고용)', lastYear),
                  _ChipOption('올해($thisYear, 예상)', thisYear),
                ],
                selectedValue: _draft.taxYear,
                onSelected: (value) => _updateDraft(
                  (draft) => draft.copyWith(taxYear: value as int),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '오늘이 ${now.year}년이면 기본 귀속연도는 ${now.year - 1}년이에요.',
                style: AppTypography.caption,
              ),
              if (result.usesEstimatedYearConstants) ...[
                const SizedBox(height: 12),
                _NoticePill(
                  text: '상수표가 없어 ${result.breakdown.appliedYear}년 기준으로 예상 계산 중',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        NotionCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TermHelpHeader(title: '소득 구성 체크', termId: 'T06'),
              const SizedBox(height: 8),
              _IncomeToggleRow(
                label: '사업소득 (필수)',
                value: true,
                enabled: false,
                onChanged: null,
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              _IncomeToggleRow(
                label: '근로소득',
                value: _draft.hasLaborIncome,
                onChanged: (value) {
                  _updateDraft(
                    (draft) => draft.copyWith(hasLaborIncome: value),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              _IncomeToggleRow(
                label: '연금소득',
                value: _draft.hasPensionIncome,
                onChanged: (value) {
                  _updateDraft(
                    (draft) => draft.copyWith(hasPensionIncome: value),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              _IncomeToggleRow(
                label: '금융소득(이자/배당)',
                value: _draft.hasFinancialIncome,
                onChanged: (value) {
                  _updateDraft(
                    (draft) => draft.copyWith(hasFinancialIncome: value),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              _IncomeToggleRow(
                label: '기타소득',
                value: _draft.hasOtherIncome,
                onChanged: (value) {
                  _updateDraft(
                    (draft) => draft.copyWith(hasOtherIncome: value),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 · 소득
  // ---------------------------------------------------------------------------

  Widget _buildStep1(String businessType) {
    final monthItems = _draft.monthlyBusinessInputs.toList()
      ..sort((a, b) => a.month.compareTo(b.month));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TermHelpHeader(title: '사업소득 입력 모드', termId: 'T07'),
              const SizedBox(height: 12),
              SegmentedButton<BusinessInputMode>(
                segments: const [
                  ButtonSegment<BusinessInputMode>(
                    value: BusinessInputMode.annual,
                    label: Text('빠른 입력(연간)'),
                  ),
                  ButtonSegment<BusinessInputMode>(
                    value: BusinessInputMode.monthly,
                    label: Text('상세 입력(월별)'),
                  ),
                ],
                selected: {_draft.businessInputMode},
                onSelectionChanged: (value) {
                  _updateDraft(
                    (draft) => draft.copyWith(businessInputMode: value.first),
                  );
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _draft.bookkeeping,
                onChanged: (value) {
                  _updateDraft((draft) => draft.copyWith(bookkeeping: value));
                },
                contentPadding: EdgeInsets.zero,
                title: const Text('장부(기장) 신고인가요?'),
                subtitle: Text(
                  _draft.bookkeeping
                      ? 'ON: 매출/경비 직접 입력(권장)'
                      : 'OFF: 단순경비율 적용(정밀도 낮음)',
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_draft.businessInputMode == BusinessInputMode.annual)
          _buildAnnualBusinessInputs(businessType)
        else
          _buildMonthlyBusinessInputs(monthItems),
        const SizedBox(height: 16),
        if (_draft.hasLaborIncome)
          _buildIncomeSection(
            kind: _IncomeKind.labor,
            title: '근로소득',
            amountTermId: 'T17',
          ),
        if (_draft.hasPensionIncome)
          _buildIncomeSection(
            kind: _IncomeKind.pension,
            title: '연금소득',
            amountTermId: 'T09',
          ),
        if (_draft.hasFinancialIncome) ...[
          _buildIncomeSection(
            kind: _IncomeKind.financial,
            title: '금융소득',
            amountTermId: 'T20',
          ),
          NotionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이자+배당 2,000만원 초과 여부',
                  style: AppTypography.textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                _buildNotionChips(
                  options: [
                    _ChipOption('예', SelectionState.yes),
                    _ChipOption('아니오', SelectionState.no),
                    _ChipOption('모르겠어요', SelectionState.unknown),
                  ],
                  selectedValue: _draft.financialOverTwentyMillion,
                  onSelected: (value) {
                    _updateDraft(
                      (draft) => draft.copyWith(
                        financialOverTwentyMillion: value as SelectionState,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_draft.hasOtherIncome)
          _buildIncomeSection(
            kind: _IncomeKind.other,
            title: '기타소득',
            amountTermId: 'T09',
          ),
      ],
    );
  }

  Widget _buildAnnualBusinessInputs(String businessType) {
    return Column(
      children: [
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TermHelpHeader(
                title: '연간 매출',
                termId: 'T07',
                statusLabel: _draft.annualSales.status.label,
              ),
              const SizedBox(height: 12),
              _amountField(
                keyName: 'annual_sales',
                value: _draft.annualSales.value,
                hint: '연간 매출(원)',
                onChanged: (field) {
                  _updateDraft((draft) => draft.copyWith(annualSales: field));
                },
              ),
              const SizedBox(height: 12),
              _buildNotionChips(
                options: [
                  _ChipOption('VAT 포함', VatInclusionChoice.included),
                  _ChipOption('VAT 미포함', VatInclusionChoice.excluded),
                  _ChipOption('모르겠어요', VatInclusionChoice.unknown),
                ],
                selectedValue: _draft.annualSalesVatMode,
                onSelected: (value) {
                  _updateDraft(
                    (draft) => draft.copyWith(
                      annualSalesVatMode: value as VatInclusionChoice,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TermHelpHeader(
                title: '연간 필요경비',
                termId: 'T08',
                statusLabel: _draft.bookkeeping
                    ? _draft.annualExpenses.status.label
                    : '단순경비율',
              ),
              const SizedBox(height: 12),
              if (_draft.bookkeeping)
                _amountField(
                  keyName: 'annual_expenses',
                  value: _draft.annualExpenses.value,
                  hint: '연간 필요경비(원)',
                  onChanged: (field) {
                    _updateDraft(
                      (draft) => draft.copyWith(annualExpenses: field),
                    );
                  },
                )
              else
                Text(
                  '단순경비율(${(_simpleExpenseRate(businessType) * 100).toStringAsFixed(1)}%)로 계산돼요.',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              if (_draft.bookkeeping) ...[
                const SizedBox(height: 12),
                _notionOutlinedButton(
                  label: '모르겠어요(업종 추정)',
                  onPressed: () {
                    final sales = _normalizeAnnualSalesForIncomeTax(
                      _draft.annualSales.value ?? 0,
                      _draft.annualSalesVatMode,
                    );
                    final estimated =
                        (sales * _industryExpenseRatio(businessType)).round();
                    _setFieldDirect(
                      keyName: 'annual_expenses',
                      field: NumericField(
                        value: estimated,
                        status: PrecisionValueStatus.estimatedIndustry,
                      ),
                      apply: (draft, field) =>
                          draft.copyWith(annualExpenses: field),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  int _normalizeAnnualSalesForIncomeTax(
    int sales,
    VatInclusionChoice vatChoice,
  ) {
    if (sales <= 0) return 0;
    return switch (vatChoice) {
      VatInclusionChoice.excluded => sales,
      VatInclusionChoice.included => (sales / 1.1).round(),
      VatInclusionChoice.unknown => (sales / 1.1).round(),
    };
  }

  PrecisionTaxDraft _migrateLegacyIndustryExpenseEstimate({
    required PrecisionTaxDraft draft,
    required String businessType,
  }) {
    if (!draft.bookkeeping) return draft;
    if (draft.businessInputMode != BusinessInputMode.annual) return draft;
    if (draft.annualSalesVatMode != VatInclusionChoice.included) return draft;
    if (!draft.annualSales.hasValue || !draft.annualExpenses.hasValue) {
      return draft;
    }
    if (draft.annualExpenses.status != PrecisionValueStatus.estimatedIndustry) {
      return draft;
    }

    final rawSales = draft.annualSales.safeValue;
    if (rawSales <= 0) return draft;

    final ratio = _industryExpenseRatio(businessType);
    final legacyEstimate = (rawSales * ratio).round();
    if (draft.annualExpenses.safeValue != legacyEstimate) return draft;

    final normalizedSales = _normalizeAnnualSalesForIncomeTax(
      rawSales,
      draft.annualSalesVatMode,
    );
    final correctedEstimate = (normalizedSales * ratio).round();
    if (correctedEstimate == legacyEstimate) return draft;

    return draft.copyWith(
      annualExpenses: NumericField(
        value: correctedEstimate,
        status: PrecisionValueStatus.estimatedIndustry,
      ),
    );
  }

  Widget _buildMonthlyBusinessInputs(List<MonthlyBusinessInput> monthItems) {
    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TermHelpHeader(title: '월별 사업소득', termId: 'T07'),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _draft.fillMissingMonths,
            onChanged: (value) {
              _updateDraft((draft) => draft.copyWith(fillMissingMonths: value));
            },
            contentPadding: EdgeInsets.zero,
            title: const Text('누락 월 추정 채우기'),
            subtitle: Text(
              'ON이면 같은 연도 평균/업종값으로 자동 보정',
              style: AppTypography.caption,
            ),
          ),
          const SizedBox(height: 8),
          for (final month in monthItems) ...[
            Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    '${month.month}월',
                    style: AppTypography.textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _compactAmountField(
                    keyName: 'm${month.month}_sales',
                    value: month.sales.value,
                    hint: '매출',
                    onChanged: (field) {
                      _updateDraft(
                        (draft) => draft.updateMonthInput(
                          month: month.month,
                          sales: field,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _compactAmountField(
                    keyName: 'm${month.month}_expenses',
                    value: month.expenses.value,
                    hint: _draft.bookkeeping ? '경비' : '경비(자동)',
                    enabled: _draft.bookkeeping,
                    onChanged: (field) {
                      _updateDraft(
                        (draft) => draft.updateMonthInput(
                          month: month.month,
                          expenses: field,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildIncomeSection({
    required _IncomeKind kind,
    required String title,
    required String amountTermId,
  }) {
    final input = _incomeInput(kind);
    final amountKey = '${kind.name}_income_amount';
    final withholdingKey = '${kind.name}_withholding';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NotionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TermHelpHeader(title: title, termId: amountTermId),
            const SizedBox(height: 12),
            _amountField(
              keyName: amountKey,
              value: input.incomeAmount.value,
              label: '소득금액',
              hint: '$title 소득금액(원)',
              statusLabel: input.incomeAmount.status.label,
              onChanged: (field) {
                _updateIncome(kind, (old) => old.copyWith(incomeAmount: field));
              },
            ),
            const SizedBox(height: 8),
            _notionOutlinedButton(
              label: '대략적인 범위 선택',
              onPressed: () async {
                final selected = await _showIncomeRangePicker(title);
                if (selected == null) return;
                _setFieldDirect(
                  keyName: amountKey,
                  field: NumericField(
                    value: selected,
                    status: PrecisionValueStatus.estimatedUser,
                  ),
                  apply: (draft, field) => _applyIncomeUpdate(
                    draft,
                    kind,
                    (old) => old.copyWith(incomeAmount: field),
                  ),
                );
              },
            ),
            const Divider(height: 32, color: AppColors.borderLight),
            _amountField(
              keyName: withholdingKey,
              value: input.withholdingTax.value,
              label: '원천징수세액',
              hint: '$title 원천징수세액(원)',
              statusLabel: input.withholdingTax.status.label,
              onChanged: (field) {
                _updateIncome(
                  kind,
                  (old) => old.copyWith(withholdingTax: field),
                );
              },
            ),
            const SizedBox(height: 8),
            _notionOutlinedButton(
              label: '모르겠어요',
              onPressed: () {
                _setFieldDirect(
                  keyName: withholdingKey,
                  field: const NumericField(
                    value: 0,
                    status: PrecisionValueStatus.estimatedZero,
                  ),
                  apply: (draft, field) => _applyIncomeUpdate(
                    draft,
                    kind,
                    (old) => old.copyWith(withholdingTax: field),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 · 공제
  // ---------------------------------------------------------------------------

  Widget _buildStep2(PrecisionTaxResult result) {
    final summary = result.breakdown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TermHelpHeader(title: '인적공제(가족)', termId: 'T15'),
              const SizedBox(height: 16),
              Text('배우자', style: AppTypography.textTheme.bodyMedium),
              const SizedBox(height: 8),
              _buildNotionChips(
                options: [
                  _ChipOption('있음', SelectionState.yes),
                  _ChipOption('없음', SelectionState.no),
                ],
                selectedValue: _draft.spouseSelection,
                onSelected: (value) {
                  _updateDraft(
                    (draft) => draft.copyWith(
                      spouseSelection: value as SelectionState,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _amountField(
                keyName: 'children_count',
                value: _draft.childrenCount.value,
                label: '부양 자녀 수',
                hint: '부양 자녀 수(명)',
                statusLabel: _draft.childrenCount.status.label,
                onChanged: (field) {
                  _updateDraft((draft) => draft.copyWith(childrenCount: field));
                },
                isCount: true,
              ),
              const SizedBox(height: 12),
              _amountField(
                keyName: 'parents_count',
                value: _draft.parentsCount.value,
                label: '부양 부모 수',
                hint: '부양 부모 수(명)',
                statusLabel: _draft.parentsCount.status.label,
                onChanged: (field) {
                  _updateDraft((draft) => draft.copyWith(parentsCount: field));
                },
                isCount: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TermHelpHeader(title: '노란우산', termId: 'T16'),
              const SizedBox(height: 12),
              _buildNotionChips(
                options: [
                  _ChipOption('가입', SelectionState.yes),
                  _ChipOption('미가입', SelectionState.no),
                ],
                selectedValue: _draft.yellowUmbrellaSelection,
                onSelected: (value) {
                  _updateDraft(
                    (draft) => draft.copyWith(
                      yellowUmbrellaSelection: value as SelectionState,
                    ),
                  );
                },
              ),
              if (_draft.yellowUmbrellaSelection == SelectionState.yes) ...[
                const SizedBox(height: 16),
                _amountField(
                  keyName: 'yellow_annual',
                  value: _draft.yellowUmbrellaAnnualPayment.value,
                  hint: '연간 납입액(원)',
                  statusLabel: _draft.yellowUmbrellaAnnualPayment.status.label,
                  onChanged: (field) {
                    _updateDraft(
                      (draft) =>
                          draft.copyWith(yellowUmbrellaAnnualPayment: field),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _notionOutlinedButton(
                  label: '모르겠어요',
                  onPressed: () {
                    _setFieldDirect(
                      keyName: 'yellow_annual',
                      field: const NumericField(
                        value: 0,
                        status: PrecisionValueStatus.estimatedZero,
                      ),
                      apply: (draft, field) =>
                          draft.copyWith(yellowUmbrellaAnnualPayment: field),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        NotionCard(
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                '감면·세액공제(선택)',
                style: AppTypography.textTheme.titleSmall,
              ),
              children: [
                TermHelpHeader(
                  title: '창업감면',
                  termId: 'T31',
                  statusLabel: _draft.startupTaxReliefRate.status.label,
                ),
                const SizedBox(height: 12),
                _buildNotionChips(
                  options: const [
                    _ChipOption('없음(0%)', StartupTaxReliefRate.none),
                    _ChipOption('50%', StartupTaxReliefRate.rate50),
                    _ChipOption('75%', StartupTaxReliefRate.rate75),
                    _ChipOption('100%', StartupTaxReliefRate.rate100),
                    _ChipOption('모르겠어요', StartupTaxReliefRate.unknown),
                  ],
                  selectedValue: _draft.startupTaxReliefRate,
                  onSelected: (value) {
                    _updateDraft(
                      (draft) => draft.copyWith(
                        startupTaxReliefRate: value as StartupTaxReliefRate,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '예상 감면액: ${Formatters.formatWonWithUnit(summary.startupTaxRelief)}',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TermHelpHeader(
                  title: '자녀세액공제(대상)',
                  termId: 'T34',
                  statusLabel: _draft.childTaxCreditCount.status.label,
                ),
                const SizedBox(height: 8),
                Text(
                  '자녀 소득금액 100만원 이하 + 만 8~20세 자녀만 입력해요.',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _amountField(
                  keyName: 'child_tax_credit_count',
                  value: _draft.childTaxCreditCount.value,
                  hint: '대상 자녀 수(명)',
                  statusLabel: _draft.childTaxCreditCount.status.label,
                  onChanged: (field) {
                    _updateDraft(
                      (draft) => draft.copyWith(childTaxCreditCount: field),
                    );
                  },
                  isCount: true,
                ),
                const SizedBox(height: 8),
                _notionOutlinedButton(
                  label: '모르겠어요',
                  onPressed: () {
                    _setFieldDirect(
                      keyName: 'child_tax_credit_count',
                      field: const NumericField(
                        value: 0,
                        status: PrecisionValueStatus.estimatedZero,
                      ),
                      apply: (draft, field) =>
                          draft.copyWith(childTaxCreditCount: field),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '예상 공제액: ${Formatters.formatWonWithUnit(summary.childTaxCredit)}',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TermHelpHeader(
                  title: '고용증대(4대보험 근로자 증가)',
                  termId: 'T32',
                  statusLabel: _draft.employmentIncreaseCount.status.label,
                ),
                const SizedBox(height: 12),
                _amountField(
                  keyName: 'employment_increase_count',
                  value: _draft.employmentIncreaseCount.value,
                  hint: '근로자 증가 인원(명)',
                  statusLabel: _draft.employmentIncreaseCount.status.label,
                  onChanged: (field) {
                    _updateDraft(
                      (draft) => draft.copyWith(employmentIncreaseCount: field),
                    );
                  },
                  isCount: true,
                ),
                const SizedBox(height: 8),
                _notionOutlinedButton(
                  label: '모르겠어요',
                  onPressed: () {
                    _setFieldDirect(
                      keyName: 'employment_increase_count',
                      field: const NumericField(
                        value: 0,
                        status: PrecisionValueStatus.estimatedZero,
                      ),
                      apply: (draft, field) =>
                          draft.copyWith(employmentIncreaseCount: field),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '예상 공제액: ${Formatters.formatWonWithUnit(summary.employmentIncreaseTaxCredit)}',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TermHelpHeader(
                  title: '기타 감면·공제',
                  termId: 'T14',
                  statusLabel: _draft.additionalTaxCredit.status.label,
                ),
                const SizedBox(height: 12),
                _amountField(
                  keyName: 'other_tax_credit',
                  value: _draft.additionalTaxCredit.value,
                  hint: '기타 감면·공제 합계(원)',
                  statusLabel: _draft.additionalTaxCredit.status.label,
                  onChanged: (field) {
                    _updateDraft(
                      (draft) => draft.copyWith(additionalTaxCredit: field),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _notionOutlinedButton(
                  label: '모르겠어요',
                  onPressed: () {
                    _setFieldDirect(
                      keyName: 'other_tax_credit',
                      field: const NumericField(
                        value: 0,
                        status: PrecisionValueStatus.estimatedZero,
                      ),
                      apply: (draft, field) =>
                          draft.copyWith(additionalTaxCredit: field),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TermHelpHeader(
                  title: '농어촌특별세(해당 시)',
                  termId: 'T33',
                  statusLabel: _draft.ruralSpecialTax.status.label,
                ),
                const SizedBox(height: 12),
                _amountField(
                  keyName: 'rural_special_tax',
                  value: _draft.ruralSpecialTax.value,
                  hint: '농어촌특별세(원)',
                  statusLabel: _draft.ruralSpecialTax.status.label,
                  onChanged: (field) {
                    _updateDraft(
                      (draft) => draft.copyWith(ruralSpecialTax: field),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _notionOutlinedButton(
                  label: '모르겠어요',
                  onPressed: () {
                    _setFieldDirect(
                      keyName: 'rural_special_tax',
                      field: const NumericField(
                        value: 0,
                        status: PrecisionValueStatus.estimatedZero,
                      ),
                      apply: (draft, field) =>
                          draft.copyWith(ruralSpecialTax: field),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '차감세액(감면·공제 합계)',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.formatWonWithUnit(summary.taxReliefTotal),
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 · 기납부
  // ---------------------------------------------------------------------------

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotionCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '추가/환급은 이미 낸 세금을 알아야 정확해요.',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _selectionAmountCard(
          title: '중간예납',
          termId: 'T19',
          selection: _draft.midtermPrepaymentSelection,
          amount: _draft.midtermPrepayment,
          keyName: 'midterm_prepayment',
          onSelection: (selection) {
            _updateDraft(
              (draft) => draft.copyWith(midtermPrepaymentSelection: selection),
            );
          },
          onAmount: (field) {
            _updateDraft((draft) => draft.copyWith(midtermPrepayment: field));
          },
        ),
        const SizedBox(height: 16),
        _selectionAmountCard(
          title: '기타 기납부',
          termId: 'T04',
          selection: _draft.otherPrepaymentSelection,
          amount: _draft.otherPrepayment,
          keyName: 'other_prepayment',
          onSelection: (selection) {
            _updateDraft(
              (draft) => draft.copyWith(otherPrepaymentSelection: selection),
            );
          },
          onAmount: (field) {
            _updateDraft((draft) => draft.copyWith(otherPrepayment: field));
          },
        ),
        const SizedBox(height: 16),
        // Summary card — visually distinct
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '기납부세액 합계',
                style: AppTypography.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                Formatters.formatWonWithUnit(_prepaymentTotal()),
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4 · 결과
  // ---------------------------------------------------------------------------

  Widget _buildStep4(PrecisionTaxResult result) {
    final summary = result.breakdown;
    final additionalPositive = summary.additionalOrRefund >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('결과 요약', style: AppTypography.textTheme.titleMedium),
                  if (result.hasEstimate) ...[
                    const SizedBox(width: 8),
                    const _NoticePill(text: '추정 포함'),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _summaryRow('총세금(결정세액)', summary.totalTax, termId: 'T03'),
              const SizedBox(height: 8),
              _summaryRow('기납부세액', summary.prepaymentTotal, termId: 'T04'),
              const Divider(height: 24, color: AppColors.border),
              _summaryRow(
                additionalPositive ? '추가 납부' : '환급 예상',
                summary.additionalOrRefund.abs(),
                valueColor: additionalPositive
                    ? AppColors.danger
                    : AppColors.success,
                termId: 'T05',
              ),
              if (result.hasEstimate) ...[
                const SizedBox(height: 12),
                Text(
                  '총세금 범위: ${Formatters.toManWon(result.totalTaxMin)} ~ ${Formatters.toManWonWithUnit(result.totalTaxMax)}',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  '추가/환급 범위: ${Formatters.toManWon(result.additionalMin)} ~ ${Formatters.toManWonWithUnit(result.additionalMax)}',
                  style: AppTypography.caption,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlossaryHelpText(
                label: '정밀도',
                termId: 'T22',
                style: AppTypography.textTheme.titleMedium,
                dense: true,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ScoreChip(
                    label:
                        '결정세액 ${result.decisionScore.value} (${result.decisionScore.label})',
                  ),
                  _ScoreChip(
                    label:
                        '추가/환급 ${result.settlementScore.value} (${result.settlementScore.label})',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (result.nextActions.isNotEmpty) ...[
          const SizedBox(height: 16),
          NotionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('다음 액션', style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 12),
                ...result.nextActions.map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ActionTile(
                      title: action.title,
                      description: action.description,
                      buttonText: '바로가기',
                      onTap: () =>
                          setState(() => _currentStep = action.stepIndex),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (result.estimatedItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          NotionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('추정 항목', style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 12),
                ...result.estimatedItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ActionTile(
                      title: item.title,
                      description: item.description,
                      buttonText: '입력하러 가기',
                      onTap: () =>
                          setState(() => _currentStep = item.stepIndex),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (result.notices.isNotEmpty) ...[
          const SizedBox(height: 16),
          NotionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('안내', style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final notice in result.notices) ...[
                  Text(
                    '• $notice',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        NotionCard(
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                '계산 근거 보기',
                style: AppTypography.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              children: [
                _breakdownRow('총소득', summary.totalIncome, termId: 'T06'),
                _breakdownRow(
                  '소득공제',
                  summary.totalIncomeDeduction,
                  termId: 'T13',
                ),
                _breakdownRow('과세표준', summary.taxableBase, termId: 'T10'),
                _breakdownRow(
                  '산출세액',
                  summary.calculatedIncomeTax,
                  termId: 'T12',
                ),
                _breakdownRow(
                  '차감세액(감면·공제)',
                  summary.taxReliefTotal,
                  termId: 'T14',
                ),
                _breakdownRow(
                  '  · 창업감면',
                  summary.startupTaxRelief,
                  termId: 'T31',
                ),
                _breakdownRow(
                  '  · 자녀 세액공제',
                  summary.childTaxCredit,
                  termId: 'T34',
                ),
                _breakdownRow(
                  '  · 고용증대 공제',
                  summary.employmentIncreaseTaxCredit,
                  termId: 'T32',
                ),
                _breakdownRow(
                  '  · 기타 감면·공제',
                  summary.otherTaxCredit,
                  termId: 'T14',
                ),
                _breakdownRow('종합소득세(국세)', summary.nationalTax, termId: 'T01'),
                _breakdownRow('농어촌특별세', summary.ruralSpecialTax, termId: 'T33'),
                _breakdownRow('지방소득세', summary.localTax, termId: 'T02'),
                _breakdownRow('총세금(결정세액)', summary.totalTax, termId: 'T03'),
                _breakdownRow('기납부세액', summary.prepaymentTotal, termId: 'T04'),
                _breakdownRow(
                  '추가/환급',
                  summary.additionalOrRefund,
                  termId: 'T05',
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared card widgets
  // ---------------------------------------------------------------------------

  Widget _selectionAmountCard({
    required String title,
    required String termId,
    required SelectionState selection,
    required NumericField amount,
    required String keyName,
    required ValueChanged<SelectionState> onSelection,
    required ValueChanged<NumericField> onAmount,
  }) {
    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TermHelpHeader(
            title: title,
            termId: termId,
            statusLabel: selection.status.label,
          ),
          const SizedBox(height: 12),
          _buildNotionChips(
            options: [
              _ChipOption('있음', SelectionState.yes),
              _ChipOption('없음', SelectionState.no),
              _ChipOption('모르겠어요', SelectionState.unknown),
            ],
            selectedValue: selection,
            onSelected: (value) {
              final sel = value as SelectionState;
              onSelection(sel);
              if (sel == SelectionState.no) {
                _syncController(keyName, 0);
                onAmount(
                  const NumericField(
                    value: 0,
                    status: PrecisionValueStatus.complete,
                  ),
                );
              } else if (sel == SelectionState.unknown) {
                _syncController(keyName, 0);
                onAmount(
                  const NumericField(
                    value: 0,
                    status: PrecisionValueStatus.estimatedZero,
                  ),
                );
              }
            },
          ),
          if (selection == SelectionState.yes) ...[
            const SizedBox(height: 12),
            _amountField(
              keyName: keyName,
              value: amount.value,
              hint: '$title 금액(원)',
              statusLabel: amount.status.label,
              onChanged: onAmount,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared form widgets
  // ---------------------------------------------------------------------------

  /// Notion-style selection chips — replaces Material ChoiceChip
  Widget _buildNotionChips({
    required List<_ChipOption> options,
    required Object? selectedValue,
    required ValueChanged<Object?> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option.value == selectedValue;
        return GestureDetector(
          onTap: () => onSelected(option.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              option.label,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Notion-style outlined button — consistent 44px touch target
  Widget _notionOutlinedButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _amountField({
    required String keyName,
    required int? value,
    required String hint,
    required ValueChanged<NumericField> onChanged,
    String? statusLabel,
    String? label,
    bool isCount = false,
  }) {
    final controller = _controllerFor(keyName, value, isCount: isCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label, style: AppTypography.textTheme.bodyMedium),
          ),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            if (!isCount) ThousandsSeparatorFormatter(),
          ],
          onChanged: (text) {
            final parsed = _parseAmount(text);
            if (parsed == null) {
              onChanged(NumericField.missing);
              return;
            }
            onChanged(
              NumericField(
                value: parsed,
                status: PrecisionValueStatus.complete,
              ),
            );
          },
          decoration: InputDecoration(
            hintText: hint,
            suffixText: isCount ? '명' : '원',
            prefixIcon: statusLabel != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    child: _StatusBadge(label: statusLabel),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactAmountField({
    required String keyName,
    required int? value,
    required String hint,
    required ValueChanged<NumericField> onChanged,
    bool enabled = true,
  }) {
    final controller = _controllerFor(keyName, value);
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        ThousandsSeparatorFormatter(),
      ],
      onChanged: (text) {
        final parsed = _parseAmount(text);
        if (parsed == null) {
          onChanged(NumericField.missing);
          return;
        }
        onChanged(
          NumericField(value: parsed, status: PrecisionValueStatus.complete),
        );
      },
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    int value, {
    Color? valueColor,
    String? termId,
  }) {
    final labelStyle = AppTypography.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    final labelWidget = termId == null
        ? Text(label, style: labelStyle)
        : GlossaryHelpText(
            label: label,
            termId: termId,
            style: labelStyle,
            dense: true,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: labelWidget),
        Text(
          Formatters.formatWonWithUnit(value),
          style: AppTypography.textTheme.titleSmall?.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _breakdownRow(String label, int amount, {String? termId}) {
    final labelWidget = termId == null
        ? Text(label, style: AppTypography.textTheme.bodyMedium)
        : GlossaryHelpText(
            label: label,
            termId: termId,
            style: AppTypography.textTheme.bodyMedium,
            dense: true,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: labelWidget),
          Text(
            Formatters.formatWonWithUnit(amount),
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Business logic (unchanged)
  // ---------------------------------------------------------------------------

  bool _canContinueStep(int step) {
    if (step == 0) return true;
    if (step == 1) {
      final hasSales = _draft.businessInputMode == BusinessInputMode.annual
          ? _draft.annualSales.hasValue
          : _draft.monthlyBusinessInputs.any((item) => item.sales.hasValue);
      final hasExpense = _draft.bookkeeping
          ? (_draft.businessInputMode == BusinessInputMode.annual
                ? _draft.annualExpenses.hasValue
                : _draft.monthlyBusinessInputs.any(
                    (item) => item.expenses.hasValue,
                  ))
          : true;
      return hasSales && hasExpense;
    }
    if (step == 2) return true;
    if (step == 3) return true;
    return false;
  }

  int _prepaymentTotal() {
    final labor = _draft.hasLaborIncome
        ? _draft.laborIncome.withholdingTax.safeValue
        : 0;
    final pension = _draft.hasPensionIncome
        ? _draft.pensionIncome.withholdingTax.safeValue
        : 0;
    final financial = _draft.hasFinancialIncome
        ? _draft.financialIncome.withholdingTax.safeValue
        : 0;
    final other = _draft.hasOtherIncome
        ? _draft.otherIncome.withholdingTax.safeValue
        : 0;
    final midterm = _draft.midtermPrepaymentSelection == SelectionState.yes
        ? _draft.midtermPrepayment.safeValue
        : 0;
    final otherPrepayment =
        _draft.otherPrepaymentSelection == SelectionState.yes
        ? _draft.otherPrepayment.safeValue
        : 0;
    return labor + pension + financial + other + midterm + otherPrepayment;
  }

  TextEditingController _controllerFor(
    String key,
    int? value, {
    bool isCount = false,
  }) {
    final text = value == null
        ? ''
        : isCount
        ? '$value'
        : Formatters.formatWon(value);
    final controller = _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: text),
    );
    return controller;
  }

  void _syncController(String key, int? value, {bool isCount = false}) {
    final controller = _controllers[key];
    if (controller == null) return;
    final text = value == null
        ? ''
        : isCount
        ? '$value'
        : Formatters.formatWon(value);
    if (controller.text == text) return;
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: text.length);
  }

  int? _parseAmount(String text) {
    final normalized = text.replaceAll(',', '').trim();
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  void _updateDraft(
    PrecisionTaxDraft Function(PrecisionTaxDraft draft) updater,
  ) {
    final next = updater(_draft);
    setState(() => _draft = next);
    context.read<BusinessProvider>().updatePrecisionTaxDraft(next);
  }

  void _setFieldDirect({
    required String keyName,
    required NumericField field,
    required PrecisionTaxDraft Function(
      PrecisionTaxDraft draft,
      NumericField field,
    )
    apply,
  }) {
    _syncController(keyName, field.value);
    _updateDraft((draft) => apply(draft, field));
  }

  Future<int?> _showIncomeRangePicker(String title) async {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final options = <_IncomeRangeOption>[
          _IncomeRangeOption(label: '0~500만원', value: 2500000),
          _IncomeRangeOption(label: '500~1,000만원', value: 7500000),
          _IncomeRangeOption(label: '1,000~3,000만원', value: 20000000),
          _IncomeRangeOption(label: '3,000~5,000만원', value: 40000000),
          _IncomeRangeOption(label: '5,000만원+', value: 60000000),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title 대략 범위 선택',
                  style: AppTypography.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...options.map(
                  (option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.label),
                    onTap: () => Navigator.of(context).pop(option.value),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IncomeCategoryInput _incomeInput(_IncomeKind kind) {
    switch (kind) {
      case _IncomeKind.labor:
        return _draft.laborIncome;
      case _IncomeKind.pension:
        return _draft.pensionIncome;
      case _IncomeKind.financial:
        return _draft.financialIncome;
      case _IncomeKind.other:
        return _draft.otherIncome;
    }
  }

  void _updateIncome(
    _IncomeKind kind,
    IncomeCategoryInput Function(IncomeCategoryInput old) updater,
  ) {
    _updateDraft((draft) => _applyIncomeUpdate(draft, kind, updater));
  }

  PrecisionTaxDraft _applyIncomeUpdate(
    PrecisionTaxDraft draft,
    _IncomeKind kind,
    IncomeCategoryInput Function(IncomeCategoryInput old) updater,
  ) {
    switch (kind) {
      case _IncomeKind.labor:
        return draft.copyWith(laborIncome: updater(draft.laborIncome));
      case _IncomeKind.pension:
        return draft.copyWith(pensionIncome: updater(draft.pensionIncome));
      case _IncomeKind.financial:
        return draft.copyWith(financialIncome: updater(draft.financialIncome));
      case _IncomeKind.other:
        return draft.copyWith(otherIncome: updater(draft.otherIncome));
    }
  }

  double _simpleExpenseRate(String businessType) {
    switch (businessType) {
      case 'restaurant':
        return 0.897;
      case 'cafe':
        return 0.878;
      default:
        return 0.897;
    }
  }

  double _industryExpenseRatio(String businessType) {
    switch (businessType) {
      case 'restaurant':
        return 0.90;
      case 'cafe':
        return 0.88;
      default:
        return 0.85;
    }
  }
}

// =============================================================================
// Private helper data classes
// =============================================================================

class _ChipOption {
  final String label;
  final Object? value;
  const _ChipOption(this.label, this.value);
}

class _IncomeRangeOption {
  final String label;
  final int value;
  const _IncomeRangeOption({required this.label, required this.value});
}

// =============================================================================
// Private widget components
// =============================================================================

class _IncomeToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const _IncomeToggleRow({
    required this.label,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: enabled ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
          SizedBox(
            height: 28,
            child: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: AppColors.surface,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              inactiveThumbColor: AppColors.surface,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline status badge shown inside TextField prefix
class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: AppColors.primaryLight,
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  const _ScoreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NoticePill extends StatelessWidget {
  final String text;
  const _NoticePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(onPressed: onTap, child: Text(buttonText)),
        ],
      ),
    );
  }
}
