import 'dart:ui';

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
import '../../models/tax_prediction.dart';
import '../../models/vat_prepayment.dart';
import '../../data/glossary_terms.dart';
import '../../utils/formatters.dart';
import '../../widgets/glossary_help_text.dart';
import '../../widgets/glossary_sheet.dart';
import '../../widgets/chip_selector.dart';
import '../../widgets/notion_card.dart';

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

  /// 다음 납부(확정신고) 기준 과세기간의 월 목록 (시작~현재월 또는 시작~기간끝)
  List<DateTime> _getVatPeriodMonths(BusinessProvider provider) {
    final period = provider.vatPeriod;
    final now = DateTime.now();
    final nowMonthStart = DateTime(now.year, now.month, 1);
    final completionEnd = nowMonthStart.isBefore(period.end)
        ? DateTime(nowMonthStart.year, nowMonthStart.month + 1, 1)
        : period.end;

    final months = <DateTime>[];
    var cursor = period.start;
    while (cursor.isBefore(completionEnd)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return months;
  }

  void _startEditing(_EditField field, BusinessProvider provider) {
    if (field == _EditField.none) return;

    _disposeEditEntries();

    final months = _getVatPeriodMonths(provider);
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
          provider.addSales(
            MonthlySales(
              yearMonth: entry.month,
              totalSales: value,
              cardSales: cardSales,
              cashReceiptSales: cashReceipt,
              otherCashSales: value - cardSales - cashReceipt,
            ),
          );
        case _EditField.expenses:
          provider.addExpenses(
            MonthlyExpenses(
              yearMonth: entry.month,
              totalExpenses: value,
              taxableExpenses: value,
            ),
          );
        case _EditField.deemed:
          provider.addDeemedPurchase(
            DeemedPurchase(yearMonth: entry.month, amount: value),
          );
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

    final titleLabel = isVat ? '부가세 상세' : '종소세 상세';

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          titleLabel,
          style: AppTypography.textTheme.titleLarge,
        ),
        centerTitle: true,
        backgroundColor: AppColors.background.withValues(alpha: 0.95),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          left: 20,
          right: 20,
          bottom: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 히어로 섹션 ──
            _buildHeroSection(provider, prediction, isVatEstimated),

            // ── 반기 계산 모드 토글 (VAT only) ──
            if (isVat) ...[
              const SizedBox(height: 16),
              _buildModeToggle(provider),
            ],

            // ── 추정 근거 (extrapolation mode) ──
            if (isVat &&
                provider.vatExtrapolationEnabled &&
                provider.vatFilledMonths > 0 &&
                provider.vatFilledMonths < 6) ...[
              const SizedBox(height: 16),
              _buildEstimationBasis(provider),
            ],

            const SizedBox(height: 24),

            // ── 구성요소 Breakdown ──
            if (isVat)
              _buildVatBreakdown(provider)
            else
              _buildIncomeTaxBreakdown(provider),

            const SizedBox(height: 24),

            // ── 계산 기준 ──
            _buildCalculationBasis(provider),

            // ── 데이터 부족 힌트 ──
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
  // 히어로 섹션
  // ============================================================

  Widget _buildHeroSection(
    BusinessProvider provider,
    TaxPrediction prediction,
    bool isVatEstimated,
  ) {
    if (!isVat) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Column(
          children: [
            Text(
              '총세금 예상액',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${Formatters.toManWon(prediction.predictedMin)} ~ ${Formatters.toManWonWithUnit(prediction.predictedMax)}',
              style: AppTypography.numDisplayLarge.copyWith(
                color: AppColors.accent,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    prediction.period,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final vatPeriod = provider.vatPeriod;

    // 결정세액(예상) 범위 (기납부 미반영)
    final decisionMin = prediction.predictedMin;
    final decisionMax = prediction.predictedMax;
    final decisionRangeText = prediction.isRefund
        ? '환급 ${Formatters.toManWon(decisionMin)} ~ ${Formatters.toManWonWithUnit(decisionMax)}'
        : '${Formatters.toManWon(decisionMin)} ~ ${Formatters.toManWonWithUnit(decisionMax)}';

    // 기납부(예정고지/예정신고)
    final prepaymentStatus = provider.vatPrepaymentStatus;
    final prepaymentEffective = provider.vatPrepaymentEffectiveAmount;
    final prepaymentText = switch (prepaymentStatus) {
      VatPrepaymentStatus.none => '없음',
      VatPrepaymentStatus.known =>
        Formatters.toManWonWithUnit(provider.vatPrepaymentAmount ?? 0),
      VatPrepaymentStatus.unknown => '모르겠어요',
      VatPrepaymentStatus.unset => '미입력',
    };

    // 실제 추가 납부/환급(예상) — 기납부 반영
    String actualLabel;
    Widget actualValue;
    bool showPrepaymentUnreflectedBadge = false;

    if (prepaymentEffective == null) {
      showPrepaymentUnreflectedBadge = true;
      if (prediction.isRefund) {
        actualLabel = '환급 가능(최소)';
        actualValue = Text(
          Formatters.toManWonWithUnit(prediction.predictedMin),
          style: AppTypography.numDisplayLarge.copyWith(
            color: AppColors.accent,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        );
      } else {
        actualLabel = '최대 추가 납부';
        actualValue = Text(
          Formatters.toManWonWithUnit(prediction.predictedMax),
          style: AppTypography.numDisplayLarge.copyWith(
            color: AppColors.accent,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        );
      }
    } else {
      // signed decision range
      final decisionSignedMin = prediction.isRefund ? -decisionMax : decisionMin;
      final decisionSignedMax = prediction.isRefund ? -decisionMin : decisionMax;

      final actualSignedMin = decisionSignedMin - prepaymentEffective;
      final actualSignedMax = decisionSignedMax - prepaymentEffective;

      if (actualSignedMin > 0) {
        actualLabel = '추가 납부(예상)';
        actualValue = Text(
          '${Formatters.toManWon(actualSignedMin)} ~ ${Formatters.toManWonWithUnit(actualSignedMax)}',
          style: AppTypography.numDisplayLarge.copyWith(
            color: AppColors.accent,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        );
      } else if (actualSignedMax < 0) {
        final refundMin = -actualSignedMax;
        final refundMax = -actualSignedMin;
        actualLabel = '환급 가능(예상)';
        actualValue = Text(
          '${Formatters.toManWon(refundMin)} ~ ${Formatters.toManWonWithUnit(refundMax)}',
          style: AppTypography.numDisplayLarge.copyWith(
            color: AppColors.accent,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        );
      } else {
        // Range crosses 0: could be additional payment or refund depending on inputs
        final maxPayable = actualSignedMax;
        final maxRefund = -actualSignedMin;
        actualLabel = '추가 납부/환급 가능';
        actualValue = Text(
          '추가 최대 +${Formatters.toManWonWithUnit(maxPayable)}\n환급 최대 ${Formatters.toManWonWithUnit(maxRefund)}',
          style: AppTypography.numDisplayMedium.copyWith(
            color: AppColors.accent,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        children: [
          Text(
            actualLabel,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          actualValue,
          if (showPrepaymentUnreflectedBadge) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '기납부 미반영',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (isVatEstimated) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  '${vatPeriod.label} (${vatPeriod.monthRangeLabel})',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NotionCard(
            onTap: () => _showVatPrepaymentSheet(provider),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '결정세액(예상)',
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      decisionRangeText,
                      style: AppTypography.numBodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '기납부',
                            style: AppTypography.textTheme.labelLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GlossaryHelpText(
                            label: '예정고지',
                            termId: 'V09',
                            dense: true,
                            style: AppTypography.textTheme.labelLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      prepaymentText,
                      style: AppTypography.numBodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '가산세/이자 미포함',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showVatPrepaymentSheet(BusinessProvider provider) async {
    VatPrepaymentStatus status = provider.vatPrepaymentStatus;
    final initialAmount = provider.vatPrepaymentAmount;
    final amountController = TextEditingController(
      text: initialAmount != null && initialAmount > 0
          ? Formatters.formatWon(initialAmount)
          : '',
    );

    String? statusToValue(VatPrepaymentStatus item) {
      return switch (item) {
        VatPrepaymentStatus.none => 'none',
        VatPrepaymentStatus.known => 'known',
        VatPrepaymentStatus.unknown => 'unknown',
        VatPrepaymentStatus.unset => null,
      };
    }

    VatPrepaymentStatus valueToStatus(String value) {
      return switch (value) {
        'none' => VatPrepaymentStatus.none,
        'known' => VatPrepaymentStatus.known,
        'unknown' => VatPrepaymentStatus.unknown,
        _ => VatPrepaymentStatus.unset,
      };
    }

    int parsedAmount() {
      final digits = amountController.text.replaceAll(',', '').trim();
      return int.tryParse(digits) ?? 0;
    }

    final term = kGlossaryTermMap['V09'];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isKnown = status == VatPrepaymentStatus.known;
            final canSave =
                status != VatPrepaymentStatus.unset &&
                (!isKnown || parsedAmount() > 0);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    '기납부(예정고지) 입력',
                    style: AppTypography.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${provider.vatPeriod.label} 확정신고에서 차감돼요',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '이번 반기에 이미 낸 부가세가 있나요?',
                    style: AppTypography.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  ChipSelector(
                    options: const [
                      ChipOption(label: '없음', value: 'none'),
                      ChipOption(label: '있음', value: 'known'),
                      ChipOption(label: '모르겠어요', value: 'unknown'),
                    ],
                    selectedValue: statusToValue(status),
                    onSelected: (value) {
                      setSheetState(() {
                        status = valueToStatus(value);
                        if (status != VatPrepaymentStatus.known) {
                          amountController.clear();
                        }
                      });
                    },
                  ),
                  if (isKnown) ...[
                    const SizedBox(height: 16),
                    Text(
                      '기납부세액 합계',
                      style: AppTypography.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorFormatter(),
                      ],
                      onChanged: (_) => setSheetState(() {}),
                      decoration: const InputDecoration(
                        hintText: '0',
                        suffixText: '원',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: term == null
                            ? null
                            : () => showWhereToFindSheet(context, term),
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: const Text('어디서 찾기'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: canSave
                                ? () {
                                    final amount =
                                        status == VatPrepaymentStatus.known
                                            ? parsedAmount()
                                            : null;
                                    provider.setVatPrepayment(
                                      status: status,
                                      amount: amount,
                                    );
                                    Navigator.pop(context);
                                  }
                                : null,
                            child: const Text('저장'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
  }

  // ============================================================
  // 반기 계산 모드 토글
  // ============================================================

  Widget _buildModeToggle(BusinessProvider provider) {
    final enabled = provider.vatExtrapolationEnabled;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _togglePill(
            label: '입력분만',
            isSelected: !enabled,
            onTap: () => provider.setVatExtrapolationEnabled(false),
          ),
          _togglePill(
            label: '반기 전체 추정',
            isSelected: enabled,
            onTap: () => provider.setVatExtrapolationEnabled(true),
          ),
        ],
      ),
    );
  }

  Widget _togglePill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.textTheme.labelMedium?.copyWith(
            color: isSelected ? AppColors.textPrimary : AppColors.textHint,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 추정 근거 (접이식)
  // ============================================================

  Widget _buildEstimationBasis(BusinessProvider provider) {
    final filled = provider.vatFilledMonths;
    final scale = filled > 0 ? (6.0 / filled) : 1.0;
    final inputBreakdown = provider.vatBreakdownInputOnly;
    final estimatedBreakdown = provider.vatBreakdown;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: true,
        title: Text(
          '추정 근거',
          style: AppTypography.textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _estimationRow('총매출', inputBreakdown.totalSales, estimatedBreakdown.totalSales),
                _estimationRow('과세매입', inputBreakdown.taxableExpenses, estimatedBreakdown.taxableExpenses),
                _estimationRow('면세매입', inputBreakdown.deemedPurchaseAmount, estimatedBreakdown.deemedPurchaseAmount),
              ],
            ),
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
              style: AppTypography.numBodySmall.copyWith(
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
              style: AppTypography.numBodySmall.copyWith(
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
  // 부가세 구성요소 (Fintech Breakdown Card)
  // ============================================================

  Widget _buildVatBreakdown(BusinessProvider provider) {
    final breakdown = provider.vatBreakdown;
    final inputBreakdown = provider.vatBreakdownInputOnly;
    final prediction = provider.vatPrediction;
    final filled = provider.vatFilledMonths;
    final otherCashSales = breakdown.otherCashSales;
    final otherCashSalesSafe = otherCashSales < 0 ? 0 : otherCashSales;
    final summaryLabel = filled > 0 ? '($filled개월 합계)' : '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 매출세액 (상단 섹션) ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _breakdownHeader(
                  label: '매출세액',
                  value: Formatters.formatWonWithUnit(breakdown.salesTax),
                  termId: 'V03',
                ),
                const SizedBox(height: 8),
                _subItemWithDetail(
                  '총매출 ${Formatters.toManWon(inputBreakdown.totalSales)} $summaryLabel',
                  _EditField.sales,
                  provider,
                ),
                const SizedBox(height: 2),
                _subItem('├', '카드매출', Formatters.toManWon(breakdown.cardSales)),
                _subItem('├', '현금영수증', Formatters.toManWon(breakdown.cashReceiptSales)),
                _subItem('└', '기타현금', Formatters.toManWon(otherCashSalesSafe)),
                _buildInlineEditor(_EditField.sales, provider, '총매출액 (원)'),
              ],
            ),
          ),

          // ── 구분선 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(height: 1, color: AppColors.borderLight),
          ),

          // ── 공제 섹션 ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 과세 매입세액
                _breakdownDeductionRow(
                  label: '과세 매입세액',
                  value: '-${Formatters.formatWonWithUnit(breakdown.purchaseTax)}',
                  termId: 'V04',
                ),
                const SizedBox(height: 4),
                _subItemWithDetail(
                  '과세매입 ${Formatters.toManWon(inputBreakdown.taxableExpenses)}',
                  _EditField.expenses,
                  provider,
                ),
                _buildInlineEditor(_EditField.expenses, provider, '과세매입액 (원)'),

                const SizedBox(height: 16),

                // 의제매입세액공제
                _breakdownDeductionRow(
                  label: '의제매입세액공제',
                  value: '-${Formatters.formatWonWithUnit(breakdown.deemedPurchaseCredit)}',
                  termId: 'V05',
                ),
                const SizedBox(height: 4),
                _subItemWithDetail(
                  '면세매입 ${Formatters.toManWon(inputBreakdown.deemedPurchaseAmount)}',
                  _EditField.deemed,
                  provider,
                ),
                _buildInlineEditor(_EditField.deemed, provider, '면세매입액 (원)'),

                const SizedBox(height: 16),

                // 신카발행세액공제
                _breakdownDeductionRow(
                  label: '신카발행세액공제',
                  value: '-${Formatters.formatWonWithUnit(breakdown.cardIssuanceCredit)}',
                  termId: 'V06',
                ),
              ],
            ),
          ),

          // ── 구분선 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(height: 1, color: AppColors.borderLight),
          ),

          // ── 차감납부세액 (합계 섹션) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '결정세액(예상)',
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  prediction.isRefund
                      ? '환급 ${Formatters.toManWon(prediction.predictedMin)} ~ ${Formatters.toManWonWithUnit(prediction.predictedMax)}'
                      : '${Formatters.toManWon(prediction.predictedMin)} ~ ${Formatters.toManWonWithUnit(prediction.predictedMax)}',
                  style: AppTypography.numDisplayMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Breakdown 헬퍼 위젯 ──

  Widget _breakdownHeader({
    required String label,
    required String value,
    String? termId,
  }) {
    return Row(
      children: [
        Expanded(
          child: _labelWithHelp(
            label,
            termId,
            style: AppTypography.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.numBody.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _breakdownDeductionRow({
    required String label,
    required String value,
    String? termId,
  }) {
    return Row(
      children: [
        Expanded(
          child: _labelWithHelp(
            label,
            termId,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.numBody.copyWith(
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _labelWithHelp(String label, String? termId, {TextStyle? style}) {
    final labelStyle = style ??
        AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        );

    if (termId == null) {
      return Text(label, overflow: TextOverflow.ellipsis, style: labelStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: GlossaryHelpText(
            label: label,
            termId: termId,
            style: labelStyle,
            dense: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 6),
        _helpIcon(termId),
      ],
    );
  }

  // ============================================================
  // 편집 가능 서브 아이템 + 인라인 편집 UI
  // ============================================================

  Widget _subItemWithDetail(
    String detailText,
    _EditField field,
    BusinessProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
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

  Widget _subItem(String prefix, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
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
            style: AppTypography.numBodySmall.copyWith(
              color: AppColors.textSecondary,
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
      crossFadeState: isEditing
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: const SizedBox.shrink(),
      secondChild: isEditing
          ? Padding(
              padding: const EdgeInsets.only(left: 8, top: 8, bottom: 4),
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
                          borderSide: const BorderSide(color: AppColors.border),
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
                                label: '${(_editCardRatio * 100).round()}%',
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
                            style: AppTypography.textTheme.bodySmall?.copyWith(
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
  // 종소세 구성요소
  // ============================================================

  Widget _buildIncomeTaxBreakdown(BusinessProvider provider) {
    final breakdown = provider.incomeTaxBreakdown;
    final profile = provider.profile;
    final prediction = provider.incomeTaxPrediction;

    String expenseLabel;
    if (profile.hasBookkeeping) {
      expenseLabel = '필요경비 (기장)';
    } else {
      final rate = breakdown.simpleExpenseRate ?? 0;
      expenseLabel = '필요경비 (추계 ${(rate * 100).toStringAsFixed(1)}%)';
    }

    final taxBase = breakdown.taxBase < 0 ? 0 : breakdown.taxBase;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 수입/경비 섹션
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _breakdownHeader(
                  label: '총수입금액',
                  value: Formatters.formatWonWithUnit(breakdown.annualRevenue),
                ),
                const SizedBox(height: 12),
                _breakdownDeductionRow(
                  label: '- $expenseLabel',
                  value: Formatters.toManWonWithUnit(breakdown.expenses),
                  termId: 'T08',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(height: 1, color: AppColors.borderLight),
          ),

          // 소득/공제 섹션
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _breakdownHeader(
                  label: '= 소득금액',
                  value: Formatters.toManWonWithUnit(breakdown.taxableIncome),
                  termId: 'T09',
                ),
                const SizedBox(height: 12),
                _breakdownDeductionRow(
                  label: '- 인적공제',
                  value: Formatters.toManWonWithUnit(breakdown.personalDeduction),
                  termId: 'T15',
                ),
                if (breakdown.yellowUmbrellaAnnual > 0) ...[
                  const SizedBox(height: 8),
                  _breakdownDeductionRow(
                    label: '- 노란우산공제',
                    value: Formatters.toManWonWithUnit(breakdown.yellowUmbrellaAnnual),
                    termId: 'T16',
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(height: 1, color: AppColors.borderLight),
          ),

          // 과세표준/세율 섹션
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _breakdownHeader(
                  label: '= 과세표준',
                  value: Formatters.toManWonWithUnit(taxBase),
                  termId: 'T10',
                ),
                const SizedBox(height: 12),
                _breakdownDeductionRow(
                  label: '세율 적용 →',
                  value: Formatters.toManWonWithUnit(breakdown.incomeTax),
                  termId: 'T11',
                ),
                const SizedBox(height: 8),
                _breakdownDeductionRow(
                  label: '+ 지방소득세 (10%)',
                  value: Formatters.toManWonWithUnit(breakdown.localTax),
                  termId: 'T02',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(height: 1, color: AppColors.borderLight),
          ),

          // 합계
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '총 결정세액',
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${Formatters.toManWon(prediction.predictedMin)} ~ ${Formatters.toManWonWithUnit(prediction.predictedMax)}',
                  style: AppTypography.numDisplayMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 계산 기준 (접이식)
  // ============================================================

  Widget _buildCalculationBasis(BusinessProvider provider) {
    final business = provider.business;
    final businessTypeLabel = switch (business.businessType) {
      'restaurant' => '음식점',
      'cafe' => '카페',
      _ => '기타',
    };
    final isRestaurant =
        business.businessType == 'restaurant' || business.businessType == 'cafe';
    final deemedRate = isRestaurant ? '8/108' : '2/102';

    final vatPeriod = provider.vatPeriod;
    final specialEnd = DateTime(2026, 12, 31, 23, 59, 59);
    final cardRate =
        !vatPeriod.constantsDate.isAfter(specialEnd) ? '1.3%' : '1.0%';
    final cardCap =
        !vatPeriod.constantsDate.isAfter(specialEnd) ? '1,000만원' : '500만원';

    final taxBase = provider.vatBreakdown.taxBase;
    final deemedLimitRate = taxBase <= 200000000 ? '50%' : '40%';

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          '계산 기준',
          style: AppTypography.textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                if (isVat) ...[
                  _basisRow('업종', businessTypeLabel),
                  _basisDivider(),
                  _basisRow('과세유형', business.taxType == 'general' ? '일반' : '간이/미정'),
                  _basisDivider(),
                  _basisRow('의제매입 공제율', deemedRate),
                  _basisDivider(),
                  _basisRow('의제매입 한도율', deemedLimitRate),
                  _basisDivider(),
                  _basisRow('신카 공제율', cardRate),
                  _basisDivider(),
                  _basisRow('신카 연간 한도', cardCap),
                  _basisDivider(),
                ],
                const SizedBox(height: 8),
                if (isVat)
                  _buildVatExplanation()
                else
                  _buildIncomeTaxExplanation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _basisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.numBodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _basisDivider() {
    return Container(height: 1, color: AppColors.borderLight);
  }

  // ============================================================
  // 공통 위젯
  // ============================================================

  Widget _helpIcon(String termId) {
    final helpMode = context.select<BusinessProvider, bool>(
      (p) => p.glossaryHelpModeEnabled,
    );
    if (helpMode) return const SizedBox.shrink();

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

  // ============================================================
  // 계산 과정 설명
  // ============================================================

  Widget _buildVatExplanation() {
    return Text(
      '결정세액 = 매출세액 - 매입세액 - 의제매입세액공제 - 신카발행세액공제\n'
      '실제 추가 납부/환급 = 결정세액 - 기납부(예정고지/예정신고)\n\n'
      '• 매출세액 = 총매출 ÷ 11 (VAT 포함 기준)\n'
      '• 매입세액 = 과세 매입 ÷ 11\n'
      '• 의제매입 = min(면세매입액, 과세표준×한도율) × 공제율 (음식점/카페 8/108)\n'
      '• 신카공제 = (카드+현금영수증) × 공제율, 연간 한도 적용\n\n'
      '※ 가산세/이자(납부지연 등)는 포함하지 않아요.',
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
            '범위가 넓은 이유:',
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
