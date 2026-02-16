import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/monthly_sales.dart';
import '../../providers/business_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/notion_card.dart';
import '../../widgets/preset_amount_picker.dart';

class FirstSalesScreen extends StatefulWidget {
  const FirstSalesScreen({super.key});

  @override
  State<FirstSalesScreen> createState() => _FirstSalesScreenState();
}

class _FirstSalesScreenState extends State<FirstSalesScreen> {
  int? _selectedAmount;
  double _cardRatio = 0.75;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '첫 매출 입력',
          style: AppTypography.textTheme.titleLarge,
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/onboarding/business-info'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    '평균 월매출이 대략 얼마인가요?',
                    style: AppTypography.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),

                  // Manual input card
                  NotionCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Text('\u{270F}\u{FE0F}',
                            style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '대략 입력하기',
                                style: AppTypography.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '정확하지 않아도 괜찮아요',
                                style:
                                    AppTypography.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Preset amount picker
                  PresetAmountPicker(
                    presets: const [10000000, 30000000, 50000000, 70000000],
                    selectedAmount: _selectedAmount,
                    onSelected: (amount) {
                      setState(() => _selectedAmount = amount);
                    },
                  ),

                  // Card ratio section (only visible after amount selected)
                  if (_selectedAmount != null) ...[
                    const SizedBox(height: 32),

                    // Card ratio slider
                    Text(
                      '카드 매출 비율은?',
                      style: AppTypography.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '50%',
                          style: AppTypography.caption,
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: AppColors.borderLight,
                              thumbColor: AppColors.primary,
                              overlayColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _cardRatio,
                              min: 0.50,
                              max: 0.95,
                              divisions: 9,
                              onChanged: (value) {
                                setState(() => _cardRatio = value);
                              },
                            ),
                          ),
                        ),
                        Text(
                          '95%',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    Center(
                      child: Text(
                        '${(_cardRatio * 100).round()}%',
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Breakdown
                    _buildBreakdown(),
                  ],
                ],
              ),
            ),
          ),

          // Bottom button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedAmount != null ? _onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textHint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '다음',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: _selectedAmount != null
                          ? AppColors.textOnPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown() {
    final total = _selectedAmount!;
    final cardAmount = (total * _cardRatio).round();
    final cashReceiptAmount = (total * 0.10).round();
    final otherCash = total - cardAmount - cashReceiptAmount;

    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '매출 구성 추정',
            style: AppTypography.textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _breakdownRow('카드', cardAmount),
          const SizedBox(height: 8),
          _breakdownRow('현금영수증', cashReceiptAmount),
          const SizedBox(height: 8),
          _breakdownRow('기타현금', otherCash.clamp(0, total)),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, int amount) {
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
          Formatters.toManWonWithUnit(amount),
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _onNext() {
    if (_selectedAmount == null) return;

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);

    final total = _selectedAmount!;
    final cardAmount = (total * _cardRatio).round();
    final cashReceiptAmount = (total * 0.10).round();
    final otherCash = (total - cardAmount - cashReceiptAmount).clamp(0, total);

    final sales = MonthlySales(
      yearMonth: currentMonth,
      totalSales: total,
      cardSales: cardAmount,
      cashReceiptSales: cashReceiptAmount,
      otherCashSales: otherCash,
    );

    final provider = Provider.of<BusinessProvider>(context, listen: false);
    provider.addSales(sales);

    context.go('/onboarding/first-result');
  }
}
