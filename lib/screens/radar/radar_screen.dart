import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/tax_card.dart';
import '../../widgets/accuracy_gauge.dart';
import '../../widgets/season_banner.dart';
import '../../widgets/tax_calendar_card.dart';

class RadarScreen extends StatelessWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final vatPrediction = provider.vatPrediction;
    final incomeTaxPrediction = provider.incomeTaxPrediction;
    final nextVatDeadline = Formatters.getNextVatDeadline();
    final nextIncomeDeadline = Formatters.getNextIncomeTaxDeadline();

    final vatDaysLeft = nextVatDeadline.difference(DateTime.now()).inDays;
    final incomeDaysLeft = nextIncomeDeadline.difference(DateTime.now()).inDays;
    final showVatBanner = vatDaysLeft <= 30 && vatDaysLeft >= 0;
    final showIncomeBanner = incomeDaysLeft <= 30 && incomeDaysLeft >= 0;

    final freshnessPercent = _calcFreshness(provider.lastUpdate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\uC138\uAE08 \uB808\uC774\uB354',
                    style: AppTypography.textTheme.headlineMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      // Notification tap - placeholder
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: const Center(
                        child: Text('\u{1F514}', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Season banners
              if (showVatBanner) ...[
                SeasonBanner(
                  taxType: '\uBD80\uAC00\uC138',
                  deadline: nextVatDeadline,
                  onTap: () => context.push('/data'),
                ),
                const SizedBox(height: 12),
              ],
              if (showIncomeBanner) ...[
                SeasonBanner(
                  taxType: '\uC885\uC18C\uC138',
                  deadline: nextIncomeDeadline,
                  onTap: () => context.push('/data'),
                ),
                const SizedBox(height: 12),
              ],

              // VAT card
              TaxCard(
                title: '\uBD80\uAC00\uC138 (${vatPrediction.period})',
                prediction: vatPrediction,
                dday: Formatters.formatDday(nextVatDeadline),
                onTap: () => context.push('/tax-detail/vat'),
              ),
              const SizedBox(height: 12),

              // Income tax card
              TaxCard(
                title: '\uC885\uC18C\uC138 (${incomeTaxPrediction.period})',
                prediction: incomeTaxPrediction,
                dday: Formatters.formatDday(nextIncomeDeadline),
                onTap: () => context.push('/tax-detail/income_tax'),
              ),
              const SizedBox(height: 12),

              // Accuracy gauge
              AccuracyGauge(
                overallPercent: provider.accuracyScore,
                salesPercent: provider.salesCompletionPercent,
                expensePercent: provider.expenseCompletionPercent,
                deemedPercent: provider.deemedCompletionPercent,
                freshnessPercent: freshnessPercent,
                onItemTap: (type) {
                  switch (type) {
                    case 'sales':
                      context.push('/data/sales-input');
                    case 'expense':
                      context.push('/data/expense-input');
                    case 'deemed':
                      context.push('/data/deemed-purchase');
                    case 'freshness':
                      context.go('/data');
                  }
                },
              ),
              const SizedBox(height: 12),

              // Tax calendar
              const TaxCalendarCard(),
              const SizedBox(height: 20),

              // Simulator button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/simulator'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.border, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: AppColors.surface,
                  ),
                  child: Text(
                    '\u{1F52E} \uC2DC\uBBAC\uB808\uC774\uD130',
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  int _calcFreshness(DateTime? lastUpdate) {
    if (lastUpdate == null) return 0;
    final daysSince = DateTime.now().difference(lastUpdate).inDays;
    if (daysSince <= 7) return 100;
    if (daysSince <= 30) return 67;
    if (daysSince <= 90) return 33;
    return 0;
  }
}
