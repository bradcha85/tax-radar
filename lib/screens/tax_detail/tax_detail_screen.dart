import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/range_bar.dart';
import '../../widgets/notion_card.dart';

class TaxDetailScreen extends StatelessWidget {
  final String taxType;

  const TaxDetailScreen({super.key, required this.taxType});

  bool get isVat => taxType == 'vat';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final prediction =
        isVat ? provider.vatPrediction : provider.incomeTaxPrediction;

    final title = isVat ? '\uBD80\uAC00\uC138 \uC0C1\uC138' : '\uC885\uC18C\uC138 \uC0C1\uC138';
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
          child: Container(
            color: AppColors.border,
            height: 1,
          ),
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
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding:
                      const EdgeInsets.only(top: 8, bottom: 4),
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
    final now = DateTime.now();
    final currentHalfStart = now.month <= 6
        ? DateTime(now.year, 1, 1)
        : DateTime(now.year, 7, 1);

    final salesList = provider.salesList
        .where((s) => !s.yearMonth.isBefore(currentHalfStart))
        .toList();
    final expensesList = provider.expensesList
        .where((e) => !e.yearMonth.isBefore(currentHalfStart))
        .toList();
    final deemedPurchases = provider.deemedPurchases
        .where((d) => !d.yearMonth.isBefore(currentHalfStart))
        .toList();

    final totalSales =
        salesList.fold<int>(0, (sum, s) => sum + s.totalSales);
    final totalCardSales = salesList.fold<int>(
      0,
      (sum, s) => sum + (s.cardSales ?? (s.totalSales * 0.75).round()),
    );
    final totalCashReceiptSales = salesList.fold<int>(
      0,
      (sum, s) =>
          sum + (s.cashReceiptSales ?? (s.totalSales * 0.10).round()),
    );
    final otherCashSales = totalSales - totalCardSales - totalCashReceiptSales;

    final totalExpenses = expensesList.fold<int>(
      0,
      (sum, e) => sum + (e.taxableExpenses ?? e.totalExpenses),
    );
    final totalDeemedAmount =
        deemedPurchases.fold<int>(0, (sum, d) => sum + d.amount);

    final business = provider.business;
    final salesTax = business.vatInclusive
        ? totalSales ~/ 11
        : (totalSales * 0.1).round();
    final purchaseTax = totalExpenses ~/ 11;

    final annualSales = totalSales * 2;
    final limitRate = annualSales <= 200000000
        ? 0.65
        : annualSales <= 400000000
            ? 0.60
            : 0.50;
    final deemedLimit = (totalDeemedAmount * limitRate).round();
    final deemedCredit = (deemedLimit * 9 / 109).round();

    final cardCreditBase = totalCardSales + totalCashReceiptSales;
    final cardCredit =
        (cardCreditBase * 0.013).round().clamp(0, 5000000);

    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sales tax
          _lineItem(
            '\uB9E4\uCD9C\uC138\uC561',
            '+${Formatters.toManWonWithUnit(salesTax)}',
            isBold: true,
          ),
          const SizedBox(height: 6),
          _subItem('\u251C', '\uCE74\uB4DC\uB9E4\uCD9C', Formatters.toManWon(totalCardSales)),
          _subItem(
              '\u251C', '\uD604\uAE08\uC601\uC218\uC99D', Formatters.toManWon(totalCashReceiptSales)),
          _subItem('\u2514', '\uAE30\uD0C0\uD604\uAE08',
              Formatters.toManWon(otherCashSales.clamp(0, otherCashSales.abs()))),
          const SizedBox(height: 16),

          // Purchase tax
          _lineItem(
            '\uACFC\uC138 \uB9E4\uC785\uC138\uC561',
            '-${Formatters.toManWonWithUnit(purchaseTax)}',
            isBold: true,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),

          // Deemed credit
          _lineItem(
            '\uC758\uC81C\uB9E4\uC785\uC138\uC561\uACF5\uC81C',
            '-${Formatters.toManWonWithUnit(deemedCredit)}',
            isBold: true,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),

          // Card credit
          _lineItem(
            '\uC2E0\uCE74\uBC1C\uD589\uC138\uC561\uACF5\uC81C',
            '-${Formatters.toManWonWithUnit(cardCredit)}',
            isBold: true,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTaxBreakdown(BusinessProvider provider) {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);

    final salesList = provider.salesList
        .where((s) => !s.yearMonth.isBefore(yearStart))
        .toList();
    final expensesList = provider.expensesList
        .where((e) => !e.yearMonth.isBefore(yearStart))
        .toList();
    final profile = provider.profile;
    final business = provider.business;

    final totalSalesRaw =
        salesList.fold<int>(0, (sum, s) => sum + s.totalSales);
    final annualRevenue = business.vatInclusive
        ? (totalSalesRaw / 1.1).round()
        : totalSalesRaw;

    int expenses;
    String expenseLabel;
    if (profile.hasBookkeeping) {
      expenses =
          expensesList.fold<int>(0, (sum, e) => sum + e.totalExpenses);
      expenseLabel = '\uD544\uC694\uACBD\uBE44 (\uAE30\uC7A5)';
    } else {
      final rate = _getSimpleExpenseRate(business.businessType);
      expenses = (annualRevenue * rate).round();
      expenseLabel = '\uD544\uC694\uACBD\uBE44 (\uCD94\uACC4 ${(rate * 100).toStringAsFixed(1)}%)';
    }

    final income = annualRevenue - expenses;
    final personalDeduction = profile.personalDeduction;
    final yellowUmbrellaAnnual = profile.yellowUmbrellaAnnual;
    final taxBase = (income - personalDeduction - yellowUmbrellaAnnual)
        .clamp(0, income * 10);

    final incomeTax = _applyTaxBracket(taxBase);
    final localTax = (incomeTax * 0.1).round();

    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lineItem('\uCD1D\uC218\uC785\uAE08\uC561', Formatters.toManWonWithUnit(annualRevenue),
              isBold: true),
          const SizedBox(height: 10),
          _lineItem('- $expenseLabel', Formatters.toManWonWithUnit(expenses),
              color: AppColors.success),
          const Divider(color: AppColors.border, height: 24),
          _lineItem('= \uC18C\uB4DD\uAE08\uC561', Formatters.toManWonWithUnit(income),
              isBold: true),
          const SizedBox(height: 10),
          _lineItem('- \uC778\uC801\uACF5\uC81C',
              Formatters.toManWonWithUnit(personalDeduction),
              color: AppColors.success),
          if (yellowUmbrellaAnnual > 0) ...[
            const SizedBox(height: 6),
            _lineItem('- \uB178\uB780\uC6B0\uC0B0\uACF5\uC81C',
                Formatters.toManWonWithUnit(yellowUmbrellaAnnual),
                color: AppColors.success),
          ],
          const Divider(color: AppColors.border, height: 24),
          _lineItem(
              '= \uACFC\uC138\uD45C\uC900', Formatters.toManWonWithUnit(taxBase),
              isBold: true),
          const SizedBox(height: 10),
          _lineItem('\uC138\uC728 \uC801\uC6A9 \u2192', Formatters.toManWonWithUnit(incomeTax)),
          const SizedBox(height: 6),
          _lineItem(
            '+ \uC9C0\uBC29\uC18C\uB4DD\uC138 (10%)',
            Formatters.toManWonWithUnit(localTax),
          ),
        ],
      ),
    );
  }

  Widget _lineItem(String label, String value,
      {bool isBold = false, Color? color}) {
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
      '\u2022 \uC758\uC81C\uB9E4\uC785 = \uB18D\uC218\uC0B0\uBB3C \uB9E4\uC785\uC561 \u00D7 \uD55C\uB3C4\uC728 \u00D7 9/109\n'
      '\u2022 \uC2E0\uCE74\uACF5\uC81C = (\uCE74\uB4DC+\uD604\uAE08\uC601\uC218\uC99D) \u00D7 1.3%, \uCD5C\uB300 500\uB9CC',
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
      BuildContext context, BusinessProvider provider) {
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

  double _getSimpleExpenseRate(String businessType) {
    switch (businessType) {
      case 'restaurant':
        return 0.897;
      case 'cafe':
        return 0.878;
      default:
        return 0.897;
    }
  }

  int _applyTaxBracket(int taxBase) {
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
}
