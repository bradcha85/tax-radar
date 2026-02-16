import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../models/monthly_sales.dart';
import '../../models/monthly_expenses.dart';
import '../../utils/formatters.dart';
import '../../utils/tax_calculator.dart';
import '../../models/tax_prediction.dart';
import '../../widgets/notion_card.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  double _salesDelta = 0;
  double _expenseDelta = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final currentVat = provider.vatPrediction;
    final currentIncome = provider.incomeTaxPrediction;

    final simVat = _simulateVat(provider);
    final simIncome = _simulateIncomeTax(provider);

    final vatDiffMin = simVat.predictedMin - currentVat.predictedMin;
    final vatDiffMax = simVat.predictedMax - currentVat.predictedMax;
    final incomeDiffMin = simIncome.predictedMin - currentIncome.predictedMin;
    final incomeDiffMax = simIncome.predictedMax - currentIncome.predictedMax;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('\uC138\uAE08 \uC2DC\uBBAC\uB808\uC774\uD130'),
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
            // Current prediction
            NotionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\uD604\uC7AC \uC608\uC0C1 \uBD80\uAC00\uC138',
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.toManWon(currentVat.predictedMin)} ~ ${Formatters.toManWonWithUnit(currentVat.predictedMax)}',
                    style: AppTypography.amountMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scenario section
            _sectionDivider('\uC2DC\uB098\uB9AC\uC624 \uC870\uC815'),
            const SizedBox(height: 16),

            // Sales slider
            NotionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\uC6D4 \uB9E4\uCD9C \uBCC0\uB3D9',
                    style: AppTypography.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.borderLight,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primaryLight,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _salesDelta,
                      min: -5000000,
                      max: 5000000,
                      divisions: 20,
                      onChanged: (v) => setState(() => _salesDelta = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('-500\uB9CC',
                          style: AppTypography.caption),
                      Text(
                        '\uD604\uC7AC: ${_formatDelta(_salesDelta.round())}',
                        style: AppTypography.textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text('+500\uB9CC',
                          style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Expense slider
            NotionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\uC6D4 \uC9C0\uCD9C \uBCC0\uB3D9',
                    style: AppTypography.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.borderLight,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primaryLight,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _expenseDelta,
                      min: -3000000,
                      max: 3000000,
                      divisions: 12,
                      onChanged: (v) => setState(() => _expenseDelta = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('-300\uB9CC',
                          style: AppTypography.caption),
                      Text(
                        '\uD604\uC7AC: ${_formatDelta(_expenseDelta.round())}',
                        style: AppTypography.textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text('+300\uB9CC',
                          style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Results section
            _sectionDivider('\uBCC0\uACBD\uB41C \uC608\uC0C1'),
            const SizedBox(height: 16),

            NotionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _resultRow(
                    '\uBD80\uAC00\uC138',
                    '${Formatters.toManWon(simVat.predictedMin)} ~ ${Formatters.toManWonWithUnit(simVat.predictedMax)}',
                  ),
                  const SizedBox(height: 12),
                  _resultRow(
                    '\uC885\uC18C\uC138',
                    '${Formatters.toManWon(simIncome.predictedMin)} ~ ${Formatters.toManWonWithUnit(simIncome.predictedMax)}',
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  Text(
                    '\uBCC0\uB3D9\uD3ED',
                    style: AppTypography.textTheme.labelMedium?.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _diffRow('\uBD80\uAC00\uC138', (vatDiffMin + vatDiffMax) ~/ 2),
                  const SizedBox(height: 4),
                  _diffRow('\uC885\uC18C\uC138', (incomeDiffMin + incomeDiffMax) ~/ 2),
                ],
              ),
            ),
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

  Widget _resultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.textTheme.bodyMedium),
        Text(value, style: AppTypography.amountSmall),
      ],
    );
  }

  Widget _diffRow(String label, int diff) {
    final isPositive = diff > 0;
    final color = isPositive ? AppColors.danger : AppColors.success;
    final prefix = isPositive ? '+' : '';
    final text = '$prefix${Formatters.toManWon(diff)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption),
        Text(
          text,
          style: AppTypography.textTheme.labelMedium?.copyWith(
            color: diff == 0 ? AppColors.textHint : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDelta(int delta) {
    if (delta == 0) return '0';
    final prefix = delta > 0 ? '+' : '';
    return '$prefix${Formatters.toManWon(delta)}';
  }

  // Simulate VAT with deltas applied per month
  TaxPrediction _simulateVat(BusinessProvider provider) {
    final now = DateTime.now();
    final currentHalfStart = now.month <= 6
        ? DateTime(now.year, 1, 1)
        : DateTime(now.year, 7, 1);
    final period = Formatters.getVatPeriod(now);

    final salesDeltaInt = _salesDelta.round();
    final expenseDeltaInt = _expenseDelta.round();

    // Apply delta to each month's sales
    final modifiedSales = provider.salesList
        .where((s) => !s.yearMonth.isBefore(currentHalfStart))
        .map((s) => MonthlySales(
              yearMonth: s.yearMonth,
              totalSales: (s.totalSales + salesDeltaInt).clamp(0, s.totalSales * 10),
              cardSales: s.cardSales,
              cashReceiptSales: s.cashReceiptSales,
              otherCashSales: s.otherCashSales,
            ))
        .toList();

    final modifiedExpenses = provider.expensesList
        .where((e) => !e.yearMonth.isBefore(currentHalfStart))
        .map((e) => MonthlyExpenses(
              yearMonth: e.yearMonth,
              totalExpenses:
                  (e.totalExpenses + expenseDeltaInt).clamp(0, e.totalExpenses * 10),
              taxableExpenses: e.taxableExpenses,
            ))
        .toList();

    final halfDeemed = provider.deemedPurchases
        .where((d) => !d.yearMonth.isBefore(currentHalfStart))
        .toList();

    return TaxCalculator.calculateVat(
      business: provider.business,
      salesList: modifiedSales,
      expensesList: modifiedExpenses,
      deemedPurchases: halfDeemed,
      accuracyScore: provider.accuracyScore,
      period: period,
    );
  }

  // Simulate income tax with deltas applied per month
  TaxPrediction _simulateIncomeTax(BusinessProvider provider) {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final period = Formatters.getIncomeTaxPeriod(now);

    final salesDeltaInt = _salesDelta.round();
    final expenseDeltaInt = _expenseDelta.round();

    final modifiedSales = provider.salesList
        .where((s) => !s.yearMonth.isBefore(yearStart))
        .map((s) => MonthlySales(
              yearMonth: s.yearMonth,
              totalSales: (s.totalSales + salesDeltaInt).clamp(0, s.totalSales * 10),
              cardSales: s.cardSales,
              cashReceiptSales: s.cashReceiptSales,
              otherCashSales: s.otherCashSales,
            ))
        .toList();

    final modifiedExpenses = provider.expensesList
        .where((e) => !e.yearMonth.isBefore(yearStart))
        .map((e) => MonthlyExpenses(
              yearMonth: e.yearMonth,
              totalExpenses:
                  (e.totalExpenses + expenseDeltaInt).clamp(0, e.totalExpenses * 10),
              taxableExpenses: e.taxableExpenses,
            ))
        .toList();

    return TaxCalculator.calculateIncomeTax(
      business: provider.business,
      salesList: modifiedSales,
      expensesList: modifiedExpenses,
      profile: provider.profile,
      accuracyScore: provider.accuracyScore,
      period: period,
    );
  }
}
