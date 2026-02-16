import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/range_bar.dart';
import '../../widgets/notion_card.dart';

class TaxDetailScreen extends StatefulWidget {
  final String taxType;

  const TaxDetailScreen({super.key, required this.taxType});

  @override
  State<TaxDetailScreen> createState() => _TaxDetailScreenState();
}

class _TaxDetailScreenState extends State<TaxDetailScreen> {
  bool get isVat => widget.taxType == 'vat';

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

    final title = isVat
        ? '\uBD80\uAC00\uC138 \uC0C1\uC138'
        : '\uC885\uC18C\uC138 \uC0C1\uC138';
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
                    '\uC608\uC0C1 \uB0A9\uBD80\uC138\uC561',
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

            // Section divider
            _sectionDivider('\uAD6C\uC131\uC694\uC18C'),
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
                    '\u25B6 \uACC4\uC0B0 \uACFC\uC815 \uBCF4\uAE30',
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

  Widget _buildVatBreakdown(BusinessProvider provider) {
    final breakdown = provider.vatBreakdown;
    final otherCashSales = breakdown.otherCashSales;
    final otherCashSalesSafe = otherCashSales < 0 ? 0 : otherCashSales;

    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sales tax
          _lineItem(
            '\uB9E4\uCD9C\uC138\uC561',
            '+${Formatters.toManWonWithUnit(breakdown.salesTax)}',
            isBold: true,
          ),
          const SizedBox(height: 6),
          _subItem(
            '\u251C',
            '\uCE74\uB4DC\uB9E4\uCD9C',
            Formatters.toManWon(breakdown.cardSales),
          ),
          _subItem(
            '\u251C',
            '\uD604\uAE08\uC601\uC218\uC99D',
            Formatters.toManWon(breakdown.cashReceiptSales),
          ),
          _subItem(
            '\u2514',
            '\uAE30\uD0C0\uD604\uAE08',
            Formatters.toManWon(otherCashSalesSafe),
          ),
          const SizedBox(height: 16),

          // Purchase tax
          _lineItem(
            '\uACFC\uC138 \uB9E4\uC785\uC138\uC561',
            '-${Formatters.toManWonWithUnit(breakdown.purchaseTax)}',
            isBold: true,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),

          // Deemed credit
          _lineItem(
            '\uC758\uC81C\uB9E4\uC785\uC138\uC561\uACF5\uC81C',
            '-${Formatters.toManWonWithUnit(breakdown.deemedPurchaseCredit)}',
            isBold: true,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),

          // Card credit
          _lineItem(
            '\uC2E0\uCE74\uBC1C\uD589\uC138\uC561\uACF5\uC81C',
            '-${Formatters.toManWonWithUnit(breakdown.cardIssuanceCredit)}',
            isBold: true,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTaxBreakdown(BusinessProvider provider) {
    final breakdown = provider.incomeTaxBreakdown;
    final profile = provider.profile;

    String expenseLabel;
    if (profile.hasBookkeeping) {
      expenseLabel = '\uD544\uC694\uACBD\uBE44 (\uAE30\uC7A5)';
    } else {
      final rate = breakdown.simpleExpenseRate ?? 0;
      expenseLabel =
          '\uD544\uC694\uACBD\uBE44 (\uCD94\uACC4 ${(rate * 100).toStringAsFixed(1)}%)';
    }

    final taxBase = breakdown.taxBase < 0 ? 0 : breakdown.taxBase;

    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lineItem(
            '\uCD1D\uC218\uC785\uAE08\uC561',
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
            '= \uC18C\uB4DD\uAE08\uC561',
            Formatters.toManWonWithUnit(breakdown.taxableIncome),
            isBold: true,
          ),
          const SizedBox(height: 10),
          _lineItem(
            '- \uC778\uC801\uACF5\uC81C',
            Formatters.toManWonWithUnit(breakdown.personalDeduction),
            color: AppColors.success,
          ),
          if (breakdown.yellowUmbrellaAnnual > 0) ...[
            const SizedBox(height: 6),
            _lineItem(
              '- \uB178\uB780\uC6B0\uC0B0\uACF5\uC81C',
              Formatters.toManWonWithUnit(breakdown.yellowUmbrellaAnnual),
              color: AppColors.success,
            ),
          ],
          const Divider(color: AppColors.border, height: 24),
          _lineItem(
            '= \uACFC\uC138\uD45C\uC900',
            Formatters.toManWonWithUnit(taxBase),
            isBold: true,
          ),
          const SizedBox(height: 10),
          _lineItem(
            '\uC138\uC728 \uC801\uC6A9 \u2192',
            Formatters.toManWonWithUnit(breakdown.incomeTax),
          ),
          const SizedBox(height: 6),
          _lineItem(
            '+ \uC9C0\uBC29\uC18C\uB4DD\uC138 (10%)',
            Formatters.toManWonWithUnit(breakdown.localTax),
          ),
        ],
      ),
    );
  }

  Widget _lineItem(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
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

  Widget _buildVatExplanation() {
    return Text(
      '\uBD80\uAC00\uC138 = \uB9E4\uCD9C\uC138\uC561 - \uB9E4\uC785\uC138\uC561 - \uC758\uC81C\uB9E4\uC785\uC138\uC561\uACF5\uC81C - \uC2E0\uCE74\uBC1C\uD589\uC138\uC561\uACF5\uC81C\n\n'
      '\u2022 \uB9E4\uCD9C\uC138\uC561 = \uCD1D\uB9E4\uCD9C \u00F7 11 (VAT \uD3EC\uD568 \uAE30\uC900)\n'
      '\u2022 \uB9E4\uC785\uC138\uC561 = \uACFC\uC138 \uB9E4\uC785 \u00F7 11\n'
      '\u2022 \uC758\uC81C\uB9E4\uC785 = min(\uBA74\uC138\uB9E4\uC785\uC561, \uACFC\uC138\uD45C\uC900\u00D7\uD55C\uB3C4\uC728) \u00D7 \uACF5\uC81C\uC728 (9/109 \uB610\uB294 8/108)\n'
      '\u2022 \uC2E0\uCE74\uACF5\uC81C = (\uCE74\uB4DC+\uD604\uAE08\uC601\uC218\uC99D) \u00D7 \uACF5\uC81C\uC728, \uC5F0\uAC04 \uD55C\uB3C4 1\uCC9C\uB9CC (2026.12.31\uAE4C\uC9C0)',
      style: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        height: 1.8,
      ),
    );
  }

  Widget _buildIncomeTaxExplanation() {
    return Text(
      '\uC885\uD569\uC18C\uB4DD\uC138 \uACC4\uC0B0 \uACFC\uC815:\n\n'
      '1. \uCD1D\uC218\uC785\uAE08\uC561 (VAT \uC81C\uC678)\n'
      '2. - \uD544\uC694\uACBD\uBE44 (\uAE30\uC7A5 \uB610\uB294 \uB2E8\uC21C\uACBD\uBE44\uC728)\n'
      '3. = \uC18C\uB4DD\uAE08\uC561\n'
      '4. - \uC778\uC801\uACF5\uC81C (\uBCF8\uC778 150\uB9CC + \uBC30\uC6B0\uC790/\uBD80\uC591\uAC00\uC871)\n'
      '5. - \uB178\uB780\uC6B0\uC0B0\uACF5\uC81C\n'
      '6. = \uACFC\uC138\uD45C\uC900\n'
      '7. \uC138\uC728\uD45C \uC801\uC6A9 (6%~45% \uB204\uC9C4)\n'
      '8. + \uC9C0\uBC29\uC18C\uB4DD\uC138 10%',
      style: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        height: 1.8,
      ),
    );
  }

  Widget _buildMissingDataHint(
    BuildContext context,
    BusinessProvider provider,
  ) {
    final missing = <String>[];
    String? route;

    if (provider.salesCompletionPercent == 0) {
      missing.add('\uB9E4\uCD9C');
      route = '/data/sales-input';
    }
    if (provider.expenseCompletionPercent == 0) {
      missing.add('\uC9C0\uCD9C');
      route ??= '/data/expense-input';
    }
    if (provider.deemedCompletionPercent == 0) {
      missing.add('\uC758\uC81C\uB9E4\uC785');
      route ??= '/data/deemed-purchase';
    }

    if (missing.isEmpty) return const SizedBox.shrink();

    final missingText = missing.join(', ');

    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u{1F4A1} \uBC94\uC704\uAC00 \uB113\uC740 \uC774\uC720:',
            style: AppTypography.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '"$missingText \uC790\uB8CC\uAC00 \uC5C6\uC5B4\uC694"',
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
                '$missingText \uC785\uB825\uD558\uAE30',
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
