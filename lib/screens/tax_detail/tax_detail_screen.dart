import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../models/monthly_sales.dart';
import '../../models/monthly_expenses.dart';
import '../../models/deemed_purchase.dart';
import '../../data/glossary_terms.dart';
import '../../utils/formatters.dart';
import '../../widgets/range_bar.dart';
import '../../widgets/notion_card.dart';
import '../../widgets/term_help_header.dart';

enum _EditField { none, sales, expenses, deemed }

class TaxDetailScreen extends StatefulWidget {
  final String taxType;

  const TaxDetailScreen({super.key, required this.taxType});

  @override
  State<TaxDetailScreen> createState() => _TaxDetailScreenState();
}

class _TaxDetailScreenState extends State<TaxDetailScreen> {
  bool get isVat => widget.taxType == 'vat';

  _EditField _editingField = _EditField.none;
  double _editCardRatio = 0.75;

  /// 월별 편집 컨트롤러 (월 → controller)
  final List<_MonthEditEntry> _editEntries = [];

  @override
  void dispose() {
    _disposeEditEntries();
    super.dispose();
  }

  void _disposeEditEntries() {
    for (final entry in _editEntries) {
      entry.controller.dispose();
    }
    _editEntries.clear();
  }

  /// 현재 반기의 1월~현재 월까지 전체 목록
  List<DateTime> _getHalfYearMonths() {
    final now = DateTime.now();
    final startMonth = now.month <= 6 ? 1 : 7;
    return [
      for (var m = startMonth; m <= now.month; m++)
        DateTime(now.year, m, 1),
    ];
  }

  void _startEditing(_EditField field, BusinessProvider provider) {
    if (field == _EditField.none) return;

    _disposeEditEntries();

    final months = _getHalfYearMonths();
    double cardRatio = 0.75;

    for (final month in months) {
      int value = 0;
      switch (field) {
        case _EditField.sales:
          final existing = provider.getSalesForMonth(month);
          if (existing != null) {
            value = existing.totalSales;
            cardRatio = existing.cardRatio;
          }
        case _EditField.expenses:
          final list = provider.expensesList.where(
            (e) =>
                e.yearMonth.year == month.year &&
                e.yearMonth.month == month.month,
          );
          if (list.isNotEmpty) {
            value = list.first.taxableExpenses ?? list.first.totalExpenses;
          }
        case _EditField.deemed:
          final list = provider.deemedPurchases.where(
            (d) =>
                d.yearMonth.year == month.year &&
                d.yearMonth.month == month.month,
          );
          if (list.isNotEmpty) {
            value = list.first.amount;
          }
        case _EditField.none:
          break;
      }

      final controller = TextEditingController(
        text: value > 0 ? Formatters.formatWon(value) : '',
      );
      _editEntries.add(_MonthEditEntry(month: month, controller: controller));
    }

    setState(() {
      _editingField = field;
      _editCardRatio = cardRatio;
    });
  }

  void _cancelEditing() {
    _disposeEditEntries();
    setState(() {
      _editingField = _EditField.none;
    });
  }

  void _saveEditing(BusinessProvider provider) {
    for (final entry in _editEntries) {
      final digits = entry.controller.text.replaceAll(',', '');
      final value = int.tryParse(digits) ?? 0;

      switch (_editingField) {
        case _EditField.sales:
          final cardSales = (value * _editCardRatio).round();
          final cashReceiptRatio = (1 - _editCardRatio) * 0.6;
          final cashReceipt = (value * cashReceiptRatio).round();
          provider.addSales(MonthlySales(
            yearMonth: entry.month,
            totalSales: value,
            cardSales: cardSales,
            cashReceiptSales: cashReceipt,
            otherCashSales: value - cardSales - cashReceipt,
          ));
        case _EditField.expenses:
          provider.addExpenses(MonthlyExpenses(
            yearMonth: entry.month,
            totalExpenses: value,
            taxableExpenses: value,
          ));
        case _EditField.deemed:
          provider.addDeemedPurchase(DeemedPurchase(
            yearMonth: entry.month,
            amount: value,
          ));
        case _EditField.none:
          break;
      }
    }

    _disposeEditEntries();
    setState(() {
      _editingField = _EditField.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final prediction = isVat
        ? provider.vatPrediction
        : provider.incomeTaxPrediction;
    final isVatEstimated =
        isVat &&
        provider.vatExtrapolationEnabled &&
        provider.salesCompletionPercent < 100;

    final title = isVat ? '부가세 상세' : '종소세 상세';
    final subtitle = prediction.period;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$title ($subtitle)'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Predicted amount header
            NotionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '예상 납부세액',
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isVatEstimated) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '추정 포함',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${Formatters.toManWon(prediction.predictedMin)} ~ ${Formatters.toManWonWithUnit(prediction.predictedMax)}',
                    style: AppTypography.amountLarge,
                  ),
                  const SizedBox(height: 12),
                  RangeBar(
                    minValue: prediction.predictedMin,
                    maxValue: prediction.predictedMax,
                    absoluteMax: (prediction.predictedMax * 1.5).round(),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            if (isVat) ...[
              const SizedBox(height: 12),
              NotionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('반기 계산 모드', style: AppTypography.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(value: false, label: Text('입력분만')),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('반기 전체 추정'),
                        ),
                      ],
                      selected: {provider.vatExtrapolationEnabled},
                      onSelectionChanged: (selection) {
                        provider.setVatExtrapolationEnabled(selection.first);
                      },
                    ),
                    if (provider.vatExtrapolationEnabled &&
                        provider.salesCompletionPercent < 100) ...[
                      const SizedBox(height: 8),
                      Text(
                        '기간 미충족 월은 평균 기반 추정이 포함돼요.',
                        style: AppTypography.caption,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Estimation basis (extrapolation mode only)
            if (isVat &&
                provider.vatExtrapolationEnabled &&
                provider.vatFilledMonths > 0 &&
                provider.vatFilledMonths < 6) ...[
              _buildEstimationBasis(provider),
              const SizedBox(height: 12),
            ],

            // Section divider
            _sectionDivider('구성요소'),
            const SizedBox(height: 12),

            // Breakdown
            if (isVat)
              _buildVatBreakdown(provider)
            else
              _buildIncomeTaxBreakdown(provider),

            const SizedBox(height: 20),

            // Calculation details
            NotionCard(
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
                  title: Text(
                    '▶ 계산 과정 보기',
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  children: [
                    if (isVat)
                      _buildVatExplanation()
                    else
                      _buildIncomeTaxExplanation(),
                  ],
                ),
              ),
            ),

            // Missing data hint
            if (prediction.accuracyScore < 50) ...[
              const SizedBox(height: 20),
              _buildMissingDataHint(context, provider),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 추정 근거 카드
  // ============================================================

  Widget _buildEstimationBasis(BusinessProvider provider) {
    final filled = provider.vatFilledMonths;
    final scale = filled > 0 ? (6.0 / filled) : 1.0;
    final inputBreakdown = provider.vatBreakdownInputOnly;
    final estimatedBreakdown = provider.vatBreakdown;

    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '추정 근거',
            style: AppTypography.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '입력 $filled개월 기반 → 6개월 추정 (×${scale.toStringAsFixed(1)}배)',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Header
          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox.shrink()),
              Expanded(
                flex: 2,
                child: Text(
                  '입력분',
                  textAlign: TextAlign.end,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '→',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  '추정분',
                  textAlign: TextAlign.end,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _estimationRow(
            '총매출',
            inputBreakdown.totalSales,
            estimatedBreakdown.totalSales,
          ),
          _estimationRow(
            '과세매입',
            inputBreakdown.taxableExpenses,
            estimatedBreakdown.taxableExpenses,
          ),
          _estimationRow(
            '면세매입',
            inputBreakdown.deemedPurchaseAmount,
            estimatedBreakdown.deemedPurchaseAmount,
          ),
        ],
      ),
    );
  }

  Widget _estimationRow(String label, int inputValue, int estimatedValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.toManWon(inputValue),
              textAlign: TextAlign.end,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '→',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.toManWon(estimatedValue),
              textAlign: TextAlign.end,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 부가세 구성요소
  // ============================================================

  Widget _buildVatBreakdown(BusinessProvider provider) {
    final breakdown = provider.vatBreakdown;
    final inputBreakdown = provider.vatBreakdownInputOnly;
    final filled = provider.vatFilledMonths;
    final otherCashSales = breakdown.otherCashSales;
    final otherCashSalesSafe = otherCashSales < 0 ? 0 : otherCashSales;

    final summaryLabel = filled > 0 ? '($filled개월 합계)' : '';

    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 매출세액 ──
          _editableLineItem(
            label: '매출세액',
            value: '+${Formatters.toManWonWithUnit(breakdown.salesTax)}',
            isBold: true,
            termId: 'V03',
            field: _EditField.sales,
            provider: provider,
          ),
          const SizedBox(height: 4),
          _subItemWithDetail(
            '총매출 ${Formatters.toManWon(inputBreakdown.totalSales)} $summaryLabel',
            _EditField.sales,
            provider,
          ),
          const SizedBox(height: 2),
          _subItem('├', '카드매출', Formatters.toManWon(breakdown.cardSales)),
          _subItem('├', '현금영수증', Formatters.toManWon(breakdown.cashReceiptSales)),
          _subItem('└', '기타현금', Formatters.toManWon(otherCashSalesSafe)),

          // 매출 인라인 편집
          _buildInlineEditor(_EditField.sales, provider, '총매출액 (원)'),

          const SizedBox(height: 16),

          // ── 과세 매입세액 ──
          _editableLineItem(
            label: '과세 매입세액',
            value: '-${Formatters.toManWonWithUnit(breakdown.purchaseTax)}',
            isBold: true,
            color: AppColors.success,
            termId: 'V04',
            field: _EditField.expenses,
            provider: provider,
          ),
          const SizedBox(height: 4),
          _subItemWithDetail(
            '과세매입 ${Formatters.toManWon(inputBreakdown.taxableExpenses)}',
            _EditField.expenses,
            provider,
          ),

          // 과세매입 인라인 편집
          _buildInlineEditor(_EditField.expenses, provider, '과세매입액 (원)'),

          const SizedBox(height: 16),

          // ── 의제매입세액공제 ──
          _editableLineItem(
            label: '의제매입세액공제',
            value: '-${Formatters.toManWonWithUnit(breakdown.deemedPurchaseCredit)}',
            isBold: true,
            color: AppColors.success,
            termId: 'V05',
            field: _EditField.deemed,
            provider: provider,
          ),
          const SizedBox(height: 4),
          _subItemWithDetail(
            '면세매입 ${Formatters.toManWon(inputBreakdown.deemedPurchaseAmount)}',
            _EditField.deemed,
            provider,
          ),

          // 면세매입 인라인 편집
          _buildInlineEditor(_EditField.deemed, provider, '면세매입액 (원)'),

          const SizedBox(height: 16),

          // ── 신카발행세액공제 ──
          _lineItem(
            '신카발행세액공제',
            '-${Formatters.toManWonWithUnit(breakdown.cardIssuanceCredit)}',
            isBold: true,
            color: AppColors.success,
            termId: 'V06',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 편집 가능 라인 아이템 + 인라인 편집 UI
  // ============================================================

  Widget _editableLineItem({
    required String label,
    required String value,
    required _EditField field,
    required BusinessProvider provider,
    String? termId,
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (termId != null) ...[
                  const SizedBox(width: 6),
                  _helpIcon(termId),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: isBold
                ? AppTypography.amountSmall.copyWith(color: color)
                : AppTypography.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _subItemWithDetail(
    String detailText,
    _EditField field,
    BusinessProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              detailText,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
          if (_editingField != field)
            GestureDetector(
              onTap: () => _startEditing(field, provider),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInlineEditor(
    _EditField field,
    BusinessProvider provider,
    String hintText,
  ) {
    final isEditing = _editingField == field;
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState:
          isEditing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox.shrink(),
      secondChild: isEditing
          ? Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 월별 TextField
                  for (var i = 0; i < _editEntries.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    TextField(
                      controller: _editEntries[i].controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: '${_editEntries[i].month.month}월',
                        hintText: hintText,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        suffixText: '원',
                      ),
                      style: AppTypography.textTheme.bodyMedium,
                      autofocus: i == 0,
                    ),
                  ],
                  if (field == _EditField.sales) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '카드비율',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: StatefulBuilder(
                            builder: (context, setSliderState) {
                              return Slider(
                                value: _editCardRatio,
                                min: 0,
                                max: 1,
                                divisions: 20,
                                label:
                                    '${(_editCardRatio * 100).round()}%',
                                onChanged: (v) {
                                  setSliderState(() {
                                    _editCardRatio = v;
                                  });
                                  setState(() {});
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${(_editCardRatio * 100).round()}%',
                            style:
                                AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _cancelEditing,
                        child: Text(
                          '취소',
                          style: AppTypography.textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _saveEditing(provider),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('저장'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ============================================================
  // 공통 위젯
  // ============================================================

  Widget _sectionDivider(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: AppTypography.textTheme.labelMedium?.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _helpIcon(String termId) {
    final term = kGlossaryTermMap[termId];
    if (term == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => showWhereToFindSheet(context, term),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          color: AppColors.surface,
        ),
        alignment: Alignment.center,
        child: Text(
          '?',
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _lineItem(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    String? termId,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (termId != null) ...[
                  const SizedBox(width: 6),
                  _helpIcon(termId),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: isBold
                ? AppTypography.amountSmall.copyWith(color: color)
                : AppTypography.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _subItem(String prefix, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
      child: Row(
        children: [
          Text(
            '$prefix ',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 종소세 구성요소
  // ============================================================

  Widget _buildIncomeTaxBreakdown(BusinessProvider provider) {
    final breakdown = provider.incomeTaxBreakdown;
    final profile = provider.profile;

    String expenseLabel;
    if (profile.hasBookkeeping) {
      expenseLabel = '필요경비 (기장)';
    } else {
      final rate = breakdown.simpleExpenseRate ?? 0;
      expenseLabel =
          '필요경비 (추계 ${(rate * 100).toStringAsFixed(1)}%)';
    }

    final taxBase = breakdown.taxBase < 0 ? 0 : breakdown.taxBase;

    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lineItem(
            '총수입금액',
            Formatters.toManWonWithUnit(breakdown.annualRevenue),
            isBold: true,
          ),
          const SizedBox(height: 10),
          _lineItem(
            '- $expenseLabel',
            Formatters.toManWonWithUnit(breakdown.expenses),
            color: AppColors.success,
          ),
          const Divider(color: AppColors.border, height: 24),
          _lineItem(
            '= 소득금액',
            Formatters.toManWonWithUnit(breakdown.taxableIncome),
            isBold: true,
          ),
          const SizedBox(height: 10),
          _lineItem(
            '- 인적공제',
            Formatters.toManWonWithUnit(breakdown.personalDeduction),
            color: AppColors.success,
          ),
          if (breakdown.yellowUmbrellaAnnual > 0) ...[
            const SizedBox(height: 6),
            _lineItem(
              '- 노란우산공제',
              Formatters.toManWonWithUnit(breakdown.yellowUmbrellaAnnual),
              color: AppColors.success,
            ),
          ],
          const Divider(color: AppColors.border, height: 24),
          _lineItem(
            '= 과세표준',
            Formatters.toManWonWithUnit(taxBase),
            isBold: true,
          ),
          const SizedBox(height: 10),
          _lineItem(
            '세율 적용 →',
            Formatters.toManWonWithUnit(breakdown.incomeTax),
          ),
          const SizedBox(height: 6),
          _lineItem(
            '+ 지방소득세 (10%)',
            Formatters.toManWonWithUnit(breakdown.localTax),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 계산 과정 설명
  // ============================================================

  Widget _buildVatExplanation() {
    return Text(
      '부가세 = 매출세액 - 매입세액 - 의제매입세액공제 - 신카발행세액공제\n\n'
      '• 매출세액 = 총매출 ÷ 11 (VAT 포함 기준)\n'
      '• 매입세액 = 과세 매입 ÷ 11\n'
      '• 의제매입 = min(면세매입액, 과세표준×한도율) × 공제율 (9/109 또는 8/108)\n'
      '• 신카공제 = (카드+현금영수증) × 공제율, 연간 한도 1천만 (2026.12.31까지)',
      style: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        height: 1.8,
      ),
    );
  }

  Widget _buildIncomeTaxExplanation() {
    return Text(
      '종합소득세 계산 과정:\n\n'
      '1. 총수입금액 (VAT 제외)\n'
      '2. - 필요경비 (기장 또는 단순경비율)\n'
      '3. = 소득금액\n'
      '4. - 인적공제 (본인 150만 + 배우자/부양가족)\n'
      '5. - 노란우산공제\n'
      '6. = 과세표준\n'
      '7. 세율표 적용 (6%~45% 누진)\n'
      '8. + 지방소득세 10%',
      style: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        height: 1.8,
      ),
    );
  }

  // ============================================================
  // 데이터 부족 힌트
  // ============================================================

  Widget _buildMissingDataHint(
    BuildContext context,
    BusinessProvider provider,
  ) {
    final missing = <String>[];
    String? route;

    if (provider.salesCompletionPercent == 0) {
      missing.add('매출');
      route = '/data/sales-input';
    }
    if (provider.expenseCompletionPercent == 0) {
      missing.add('지출');
      route ??= '/data/expense-input';
    }
    if (provider.deemedCompletionPercent == 0) {
      missing.add('의제매입');
      route ??= '/data/deemed-purchase';
    }

    if (missing.isEmpty) return const SizedBox.shrink();

    final missingText = missing.join(', ');

    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u{1F4A1} 범위가 넓은 이유:',
            style: AppTypography.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '"$missingText 자료가 없어요"',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: route != null ? () => context.push(route!) : null,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '$missingText 입력하기',
                style: AppTypography.textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthEditEntry {
  final DateTime month;
  final TextEditingController controller;

  _MonthEditEntry({required this.month, required this.controller});
}
