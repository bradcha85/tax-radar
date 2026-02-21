import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../models/monthly_sales.dart';
import '../../utils/formatters.dart';

class SalesInputScreen extends StatefulWidget {
  const SalesInputScreen({super.key});

  @override
  State<SalesInputScreen> createState() => _SalesInputScreenState();
}

class _SalesInputScreenState extends State<SalesInputScreen> {
  late List<DateTime> _months;
  late DateTime _selectedMonth;
  final _totalController = TextEditingController();
  double _cardRatio = 0.75;

  @override
  void initState() {
    super.initState();
    _months = _getLast6Months();
    _selectedMonth = _months.last;
    _loadExistingData();
  }

  List<DateTime> _getLast6Months() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      return DateTime(now.year, now.month - 5 + i, 1);
    });
  }

  void _loadExistingData() {
    final provider = context.read<BusinessProvider>();
    final existing = provider.getSalesForMonth(_selectedMonth);
    if (existing != null) {
      _totalController.text = Formatters.formatWon(existing.totalSales);
      _cardRatio = existing.cardRatio.clamp(0.5, 0.95);
    } else {
      _totalController.clear();
      _cardRatio = 0.75;
    }
  }

  int get _totalSales {
    final text = _totalController.text.replaceAll(',', '');
    return int.tryParse(text) ?? 0;
  }

  int get _cardSales => (_totalSales * _cardRatio).round();
  int get _cashReceiptSales => (_totalSales * 0.10).round();
  int get _otherCashSales => (_totalSales - _cardSales - _cashReceiptSales).clamp(0, _totalSales);

  bool _monthHasData(DateTime month) {
    final provider = context.read<BusinessProvider>();
    return provider.getSalesForMonth(month) != null;
  }

  void _onSave() {
    if (_totalSales <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('매출 금액을 입력해 주세요')));
      return;
    }

    final sales = MonthlySales(
      yearMonth: _selectedMonth,
      totalSales: _totalSales,
      cardSales: _cardSales,
      cashReceiptSales: _cashReceiptSales,
      otherCashSales: _otherCashSales,
    );

    context.read<BusinessProvider>().addSales(sales);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('저장되었습니다')));
    context.pop();
  }

  @override
  void dispose() {
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('매출 입력'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month selector
            Text('월별 현황', style: AppTypography.textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _months.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final month = _months[index];
                  final isSelected =
                      month.year == _selectedMonth.year &&
                      month.month == _selectedMonth.month;
                  final hasData = _monthHasData(month);

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedMonth = month);
                      _loadExistingData();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Formatters.formatMonth(month),
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? AppColors.textOnPrimary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (hasData) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: isSelected
                                  ? AppColors.textOnPrimary
                                  : AppColors.success,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Total sales
            Text(
              '${Formatters.formatMonth(_selectedMonth)} 매출 입력',
              style: AppTypography.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text('총 매출', style: AppTypography.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _totalController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorFormatter(),
              ],
              style: AppTypography.amountSmall,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: AppTypography.hint.copyWith(fontSize: 16),
                suffixText: '원',
                suffixStyle: AppTypography.textTheme.bodyMedium,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Card ratio slider
            Text('카드 매출 비율', style: AppTypography.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.borderLight,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.1),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _cardRatio,
                      min: 0.50,
                      max: 0.95,
                      divisions: 9,
                      onChanged: (v) => setState(() => _cardRatio = v),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_cardRatio * 100).round()}%',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Breakdown
            if (_totalSales > 0) ...[
              Text('매출 내역 (자동 계산)', style: AppTypography.textTheme.titleSmall),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _BreakdownRow(label: '카드매출', amount: _cardSales),
                    const Divider(height: 20, color: AppColors.borderLight),
                    _BreakdownRow(label: '현금영수증', amount: _cashReceiptSales),
                    const Divider(height: 20, color: AppColors.borderLight),
                    _BreakdownRow(label: '기타현금', amount: _otherCashSales),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '저장하기',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int amount;

  const _BreakdownRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.textTheme.bodyMedium),
        Text(
          Formatters.toManWonWithUnit(amount),
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
