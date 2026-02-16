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
    _draft = context.read<BusinessProvider>().precisionTaxDraft;
    _isInitialized = true;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

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
        title: const Text('정밀 종소세'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: () => context.push('/glossary'),
            child: const Text('용어 사전'),
          ),
        ],
      ),
      body: SafeArea(
        child: Stepper(
          currentStep: _currentStep,
          type: StepperType.vertical,
          onStepTapped: (index) => setState(() => _currentStep = index),
          onStepCancel: _currentStep == 0
              ? null
              : () => setState(() => _currentStep -= 1),
          onStepContinue: () {
            if (_currentStep >= 4) return;
            if (!_canContinueStep(_currentStep)) return;
            setState(() => _currentStep += 1);
          },
          controlsBuilder: (context, details) {
            final isLast = _currentStep == 4;
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (!isLast)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _canContinueStep(_currentStep)
                            ? details.onStepContinue
                            : null,
                        child: Text(_currentStep == 3 ? '결과 보기' : '다음'),
                      ),
                    ),
                  if (!isLast) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentStep == 0
                          ? () => context.pop()
                          : details.onStepCancel,
                      child: Text(_currentStep == 0 ? '닫기' : '이전'),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Step 0 · 시작'),
              isActive: _currentStep >= 0,
              content: _buildStep0(result),
            ),
            Step(
              title: const Text('Step 1 · 소득'),
              isActive: _currentStep >= 1,
              content: _buildStep1(provider.business.businessType),
            ),
            Step(
              title: const Text('Step 2 · 공제'),
              isActive: _currentStep >= 2,
              content: _buildStep2(),
            ),
            Step(
              title: const Text('Step 3 · 기납부'),
              isActive: _currentStep >= 3,
              content: _buildStep3(),
            ),
            Step(
              title: const Text('Step 4 · 결과'),
              isActive: _currentStep >= 4,
              content: _buildStep4(result),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0(PrecisionTaxResult result) {
    final now = DateTime.now();
    final lastYear = now.year - 1;
    final thisYear = now.year;
    final directYears = <int>{2025, lastYear, thisYear}.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TermHelpHeader(
                title: '귀속연도 선택',
                termId: 'T21',
                onTermViewed: _onTermViewed,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('작년($lastYear, 신고용)'),
                    selected: _draft.taxYear == lastYear,
                    onSelected: (_) => _updateDraft(
                      (draft) => draft.copyWith(taxYear: lastYear),
                    ),
                  ),
                  ChoiceChip(
                    label: Text('올해($thisYear, 예상)'),
                    selected: _draft.taxYear == thisYear,
                    onSelected: (_) => _updateDraft(
                      (draft) => draft.copyWith(taxYear: thisYear),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                key: ValueKey<int>(_draft.taxYear),
                initialValue: _draft.taxYear,
                decoration: const InputDecoration(labelText: '직접 선택'),
                items: directYears
                    .map(
                      (year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text('$year년'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _updateDraft((draft) => draft.copyWith(taxYear: value));
                },
              ),
              const SizedBox(height: 10),
              Text(
                '오늘이 ${now.year}년이면 기본 귀속연도는 ${now.year - 1}년이에요.',
                style: AppTypography.caption,
              ),
              if (result.usesEstimatedYearConstants) ...[
                const SizedBox(height: 8),
                _NoticePill(
                  text: '상수표가 없어 ${result.breakdown.appliedYear}년 기준으로 예상 계산 중',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TermHelpHeader(
                title: '소득 구성 체크',
                termId: 'T06',
                onTermViewed: _onTermViewed,
              ),
              const SizedBox(height: 8),
              _IncomeToggleRow(
                label: '사업소득 (필수)',
                value: true,
                enabled: false,
                onChanged: null,
              ),
              _IncomeToggleRow(
                label: '근로소득',
                value: _draft.hasLaborIncome,
                onChanged: (value) {
                  _updateDraft(
                    (draft) => draft.copyWith(hasLaborIncome: value),
                  );
                },
              ),
              _IncomeToggleRow(
                label: '연금소득',
                value: _draft.hasPensionIncome,
                onChanged: (value) {
                  _updateDraft(
                    (draft) => draft.copyWith(hasPensionIncome: value),
                  );
                },
              ),
              _IncomeToggleRow(
                label: '금융소득(이자/배당)',
                value: _draft.hasFinancialIncome,
                onChanged: (value) {
                  _updateDraft(
                    (draft) => draft.copyWith(hasFinancialIncome: value),
                  );
                },
              ),
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
              TermHelpHeader(
                title: '사업소득 입력 모드',
                termId: 'T07',
                onTermViewed: _onTermViewed,
              ),
              const SizedBox(height: 8),
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
        const SizedBox(height: 12),
        if (_draft.businessInputMode == BusinessInputMode.annual)
          _buildAnnualBusinessInputs(businessType)
        else
          _buildMonthlyBusinessInputs(monthItems),
        const SizedBox(height: 12),
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
          const SizedBox(height: 8),
          NotionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이자+배당 2,000만원 초과 여부',
                  style: AppTypography.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('예'),
                      selected:
                          _draft.financialOverTwentyMillion ==
                          SelectionState.yes,
                      onSelected: (_) {
                        _updateDraft(
                          (draft) => draft.copyWith(
                            financialOverTwentyMillion: SelectionState.yes,
                          ),
                        );
                      },
                    ),
                    ChoiceChip(
                      label: const Text('아니오'),
                      selected:
                          _draft.financialOverTwentyMillion ==
                          SelectionState.no,
                      onSelected: (_) {
                        _updateDraft(
                          (draft) => draft.copyWith(
                            financialOverTwentyMillion: SelectionState.no,
                          ),
                        );
                      },
                    ),
                    ChoiceChip(
                      label: const Text('모르겠어요'),
                      selected:
                          _draft.financialOverTwentyMillion ==
                          SelectionState.unknown,
                      onSelected: (_) {
                        _updateDraft(
                          (draft) => draft.copyWith(
                            financialOverTwentyMillion: SelectionState.unknown,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                onTermViewed: _onTermViewed,
              ),
              const SizedBox(height: 10),
              _amountField(
                keyName: 'annual_sales',
                value: _draft.annualSales.value,
                hint: '연간 매출(원)',
                onChanged: (field) {
                  _updateDraft((draft) => draft.copyWith(annualSales: field));
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('VAT 포함'),
                    selected:
                        _draft.annualSalesVatMode ==
                        VatInclusionChoice.included,
                    onSelected: (_) {
                      _updateDraft(
                        (draft) => draft.copyWith(
                          annualSalesVatMode: VatInclusionChoice.included,
                        ),
                      );
                    },
                  ),
                  ChoiceChip(
                    label: const Text('VAT 미포함'),
                    selected:
                        _draft.annualSalesVatMode ==
                        VatInclusionChoice.excluded,
                    onSelected: (_) {
                      _updateDraft(
                        (draft) => draft.copyWith(
                          annualSalesVatMode: VatInclusionChoice.excluded,
                        ),
                      );
                    },
                  ),
                  ChoiceChip(
                    label: const Text('모르겠어요'),
                    selected:
                        _draft.annualSalesVatMode == VatInclusionChoice.unknown,
                    onSelected: (_) {
                      _updateDraft(
                        (draft) => draft.copyWith(
                          annualSalesVatMode: VatInclusionChoice.unknown,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
                onTermViewed: _onTermViewed,
              ),
              const SizedBox(height: 10),
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        final sales = _draft.annualSales.value ?? 0;
                        final estimated =
                            (sales * _industryExpenseRatio(businessType))
                                .round();
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
                      child: const Text('모르겠어요(업종 추정)'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _setFieldDirect(
                          keyName: 'annual_expenses',
                          field: const NumericField(
                            value: 0,
                            status: PrecisionValueStatus.complete,
                          ),
                          apply: (draft, field) =>
                              draft.copyWith(annualExpenses: field),
                        );
                      },
                      child: const Text('0원'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyBusinessInputs(List<MonthlyBusinessInput> monthItems) {
    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TermHelpHeader(
            title: '월별 사업소득',
            termId: 'T07',
            onTermViewed: _onTermViewed,
          ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: NotionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TermHelpHeader(
              title: title,
              termId: amountTermId,
              onTermViewed: _onTermViewed,
            ),
            const SizedBox(height: 10),
            _amountField(
              keyName: amountKey,
              value: input.incomeAmount.value,
              hint: '$title 소득금액(원)',
              statusLabel: input.incomeAmount.status.label,
              onChanged: (field) {
                _updateIncome(kind, (old) => old.copyWith(incomeAmount: field));
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
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
                  child: const Text('소득금액 모르겠어요'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _amountField(
              keyName: withholdingKey,
              value: input.withholdingTax.value,
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
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _setFieldDirect(
                      keyName: withholdingKey,
                      field: const NumericField(
                        value: 0,
                        status: PrecisionValueStatus.complete,
                      ),
                      apply: (draft, field) => _applyIncomeUpdate(
                        draft,
                        kind,
                        (old) => old.copyWith(withholdingTax: field),
                      ),
                    );
                  },
                  child: const Text('0원'),
                ),
                OutlinedButton(
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
                  child: const Text('모르겠어요(추정 0)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TermHelpHeader(
                title: '인적공제(가족)',
                termId: 'T15',
                onTermViewed: _onTermViewed,
              ),
              const SizedBox(height: 10),
              Text('배우자', style: AppTypography.textTheme.bodyMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('있음'),
                    selected: _draft.spouseSelection == SelectionState.yes,
                    onSelected: (_) {
                      _updateDraft(
                        (draft) =>
                            draft.copyWith(spouseSelection: SelectionState.yes),
                      );
                    },
                  ),
                  ChoiceChip(
                    label: const Text('없음'),
                    selected: _draft.spouseSelection == SelectionState.no,
                    onSelected: (_) {
                      _updateDraft(
                        (draft) =>
                            draft.copyWith(spouseSelection: SelectionState.no),
                      );
                    },
                  ),
                  ChoiceChip(
                    label: const Text('모르겠어요'),
                    selected: _draft.spouseSelection == SelectionState.unknown,
                    onSelected: (_) {
                      _updateDraft(
                        (draft) => draft.copyWith(
                          spouseSelection: SelectionState.unknown,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _amountField(
                keyName: 'children_count',
                value: _draft.childrenCount.value,
                hint: '자녀 수(명)',
                statusLabel: _draft.childrenCount.status.label,
                onChanged: (field) {
                  _updateDraft((draft) => draft.copyWith(childrenCount: field));
                },
                isCount: true,
              ),
              const SizedBox(height: 8),
              _amountField(
                keyName: 'parents_count',
                value: _draft.parentsCount.value,
                hint: '부모 부양 수(명)',
                statusLabel: _draft.parentsCount.status.label,
                onChanged: (field) {
                  _updateDraft((draft) => draft.copyWith(parentsCount: field));
                },
                isCount: true,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _setFieldDirect(
                        keyName: 'children_count',
                        field: const NumericField(
                          value: 0,
                          status: PrecisionValueStatus.estimatedUser,
                        ),
                        apply: (draft, field) =>
                            draft.copyWith(childrenCount: field),
                      );
                    },
                    child: const Text('자녀 모르겠어요'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _setFieldDirect(
                        keyName: 'parents_count',
                        field: const NumericField(
                          value: 0,
                          status: PrecisionValueStatus.estimatedUser,
                        ),
                        apply: (draft, field) =>
                            draft.copyWith(parentsCount: field),
                      );
                    },
                    child: const Text('부모 모르겠어요'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TermHelpHeader(
                title: '노란우산',
                termId: 'T16',
                onTermViewed: _onTermViewed,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('가입'),
                    selected:
                        _draft.yellowUmbrellaSelection == SelectionState.yes,
                    onSelected: (_) {
                      _updateDraft(
                        (draft) => draft.copyWith(
                          yellowUmbrellaSelection: SelectionState.yes,
                        ),
                      );
                    },
                  ),
                  ChoiceChip(
                    label: const Text('미가입'),
                    selected:
                        _draft.yellowUmbrellaSelection == SelectionState.no,
                    onSelected: (_) {
                      _updateDraft(
                        (draft) => draft.copyWith(
                          yellowUmbrellaSelection: SelectionState.no,
                        ),
                      );
                    },
                  ),
                  ChoiceChip(
                    label: const Text('모르겠어요'),
                    selected:
                        _draft.yellowUmbrellaSelection ==
                        SelectionState.unknown,
                    onSelected: (_) {
                      _updateDraft(
                        (draft) => draft.copyWith(
                          yellowUmbrellaSelection: SelectionState.unknown,
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (_draft.yellowUmbrellaSelection == SelectionState.yes) ...[
                const SizedBox(height: 12),
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
                OutlinedButton(
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
                  child: const Text('모르겠어요(0원)'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        NotionCard(
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                '더 정확하게(선택)',
                style: AppTypography.textTheme.titleSmall,
              ),
              children: [
                _amountField(
                  keyName: 'additional_tax_credit',
                  value: _draft.additionalTaxCredit.value,
                  hint: '추가 세액공제 합계(원)',
                  statusLabel: _draft.additionalTaxCredit.status.label,
                  onChanged: (field) {
                    _updateDraft(
                      (draft) => draft.copyWith(additionalTaxCredit: field),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '추가/환급은 이미 낸 세금을 알아야 정확해요.',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_draft.hasLaborIncome)
          _withholdingCard(kind: _IncomeKind.labor, label: '근로 원천징수'),
        if (_draft.hasPensionIncome)
          _withholdingCard(kind: _IncomeKind.pension, label: '연금 원천징수'),
        if (_draft.hasFinancialIncome)
          _withholdingCard(kind: _IncomeKind.financial, label: '금융 원천징수'),
        if (_draft.hasOtherIncome)
          _withholdingCard(kind: _IncomeKind.other, label: '기타 원천징수'),
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
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        NotionCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('기납부세액 합계', style: AppTypography.textTheme.titleSmall),
              Text(
                Formatters.formatWonWithUnit(_prepaymentTotal()),
                style: AppTypography.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
              const SizedBox(height: 12),
              _summaryRow('총세금(결정세액)', summary.totalTax),
              const SizedBox(height: 6),
              _summaryRow('기납부세액', summary.prepaymentTotal),
              const Divider(height: 24, color: AppColors.border),
              _summaryRow(
                additionalPositive ? '추가 납부' : '환급 예상',
                summary.additionalOrRefund.abs(),
                valueColor: additionalPositive
                    ? AppColors.danger
                    : AppColors.success,
              ),
              if (result.hasEstimate) ...[
                const SizedBox(height: 8),
                Text(
                  '총세금 범위: ${Formatters.toManWon(result.totalTaxMin)} ~ ${Formatters.toManWonWithUnit(result.totalTaxMax)}',
                  style: AppTypography.caption,
                ),
                Text(
                  '추가/환급 범위: ${Formatters.toManWon(result.additionalMin)} ~ ${Formatters.toManWonWithUnit(result.additionalMax)}',
                  style: AppTypography.caption,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        NotionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('정밀도', style: AppTypography.textTheme.titleMedium),
              const SizedBox(height: 10),
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
          const SizedBox(height: 8),
          NotionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('다음 액션', style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          NotionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('추정 항목', style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          NotionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('안내', style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final notice in result.notices) ...[
                  Text(
                    '• $notice',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
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
                _breakdownRow('총소득', summary.totalIncome),
                _breakdownRow('소득공제', summary.totalIncomeDeduction),
                _breakdownRow('과세표준', summary.taxableBase),
                _breakdownRow('산출세액', summary.calculatedIncomeTax),
                _breakdownRow('세액공제', summary.additionalTaxCredit),
                _breakdownRow('종합소득세(국세)', summary.nationalTax),
                _breakdownRow('지방소득세', summary.localTax),
                _breakdownRow('총세금(결정세액)', summary.totalTax),
                _breakdownRow('기납부세액', summary.prepaymentTotal),
                _breakdownRow('추가/환급', summary.additionalOrRefund),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _withholdingCard({required _IncomeKind kind, required String label}) {
    final input = _incomeInput(kind);
    final keyName = '${kind.name}_withholding';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NotionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TermHelpHeader(
              title: label,
              termId: 'T18',
              statusLabel: input.withholdingTax.status.label,
              onTermViewed: _onTermViewed,
            ),
            const SizedBox(height: 10),
            _amountField(
              keyName: keyName,
              value: input.withholdingTax.value,
              hint: '$label 금액(원)',
              onChanged: (field) {
                _updateIncome(
                  kind,
                  (old) => old.copyWith(withholdingTax: field),
                );
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _setFieldDirect(
                      keyName: keyName,
                      field: const NumericField(
                        value: 0,
                        status: PrecisionValueStatus.complete,
                      ),
                      apply: (draft, field) => _applyIncomeUpdate(
                        draft,
                        kind,
                        (old) => old.copyWith(withholdingTax: field),
                      ),
                    );
                  },
                  child: const Text('0원'),
                ),
                OutlinedButton(
                  onPressed: () {
                    _setFieldDirect(
                      keyName: keyName,
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
                  child: const Text('모르겠어요'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
            onTermViewed: _onTermViewed,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('있음'),
                selected: selection == SelectionState.yes,
                onSelected: (_) => onSelection(SelectionState.yes),
              ),
              ChoiceChip(
                label: const Text('없음'),
                selected: selection == SelectionState.no,
                onSelected: (_) {
                  onSelection(SelectionState.no);
                  _syncController(keyName, 0);
                  onAmount(
                    const NumericField(
                      value: 0,
                      status: PrecisionValueStatus.complete,
                    ),
                  );
                },
              ),
              ChoiceChip(
                label: const Text('모르겠어요'),
                selected: selection == SelectionState.unknown,
                onSelected: (_) {
                  onSelection(SelectionState.unknown);
                  _syncController(keyName, 0);
                  onAmount(
                    const NumericField(
                      value: 0,
                      status: PrecisionValueStatus.estimatedZero,
                    ),
                  );
                },
              ),
            ],
          ),
          if (selection == SelectionState.yes) ...[
            const SizedBox(height: 10),
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

  Widget _amountField({
    required String keyName,
    required int? value,
    required String hint,
    required ValueChanged<NumericField> onChanged,
    String? statusLabel,
    bool isCount = false,
  }) {
    final controller = _controllerFor(keyName, value, isCount: isCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (statusLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              statusLabel,
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            if (!isCount) _ThousandsSeparatorFormatter(),
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
        _ThousandsSeparatorFormatter(),
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

  Widget _summaryRow(String label, int value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
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

  Widget _breakdownRow(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.textTheme.bodyMedium),
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

  void _onTermViewed(String termId) {
    context.read<BusinessProvider>().markRecentGlossary(termId);
  }

  Future<int?> _showIncomeRangePicker(String title) async {
    return showModalBottomSheet<int>(
      context: context,
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

class _IncomeRangeOption {
  final String label;
  final int value;

  const _IncomeRangeOption({required this.label, required this.value});
}

class _IncomeToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const _IncomeToggleRow({
    required this.label,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;

  const _ScoreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(999),
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
          const SizedBox(width: 10),
          TextButton(onPressed: onTap, child: Text(buttonText)),
        ],
      ),
    );
  }
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final digits = newValue.text.replaceAll(',', '');
    final value = int.tryParse(digits);
    if (value == null) return oldValue;
    final text = Formatters.formatWon(value);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
