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
                    '세금 레이더',
                    style: AppTypography.textTheme.headlineMedium,
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Notification tap - placeholder
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 22,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Season banners
              if (showVatBanner) ...[
                SeasonBanner(
                  taxType: '부가세',
                  deadline: nextVatDeadline,
                  onTap: () => context.push('/data'),
                ),
                const SizedBox(height: 16),
              ],
              if (showIncomeBanner) ...[
                SeasonBanner(
                  taxType: '종소세',
                  deadline: nextIncomeDeadline,
                  onTap: () => context.push('/data'),
                ),
                const SizedBox(height: 16),
              ],

              // VAT card
              TaxCard(
                title: '부가세 (${vatPrediction.period})',
                prediction: vatPrediction,
                dday: Formatters.formatDday(nextVatDeadline),
                onTap: () => context.push('/tax-detail/vat'),
              ),
              const SizedBox(height: 16),

              // Income tax card
              TaxCard(
                title: '종소세 (${incomeTaxPrediction.period})',
                prediction: incomeTaxPrediction,
                dday: Formatters.formatDday(nextIncomeDeadline),
                onTap: () => context.push('/tax-detail/income_tax'),
              ),
              const SizedBox(height: 12),

              // Precision tax button
              _NotionActionButton(
                icon: Icons.calculate_outlined,
                label: '정밀 종소세 계산',
                onTap: () => context.push('/precision-tax'),
                isPrimary: true,
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 16),

              // Tax calendar
              const TaxCalendarCard(),
              const SizedBox(height: 16),

              // Simulator button
              _NotionActionButton(
                icon: Icons.science_outlined,
                label: '시뮬레이터',
                onTap: () => context.push('/simulator'),
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

class _NotionActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _NotionActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: isPrimary ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPrimary ? AppColors.primary : AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isPrimary ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    color: isPrimary ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
