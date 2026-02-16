import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../models/deemed_purchase.dart';
import '../../utils/formatters.dart';
import '../../widgets/preset_amount_picker.dart';

class DeemedPurchaseScreen extends StatefulWidget {
  const DeemedPurchaseScreen({super.key});

  @override
  State<DeemedPurchaseScreen> createState() => _DeemedPurchaseScreenState();
}

class _DeemedPurchaseScreenState extends State<DeemedPurchaseScreen> {
  late List<DateTime> _months;
  late DateTime _selectedMonth;
  int? _selectedAmount;

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
    final existing = provider.deemedPurchases
        .where(
          (d) =>
              d.yearMonth.year == _selectedMonth.year &&
              d.yearMonth.month == _selectedMonth.month,
        )
        .toList();
    if (existing.isNotEmpty) {
      _selectedAmount = existing.first.amount;
    } else {
      _selectedAmount = null;
    }
  }

  int? _getPreviousMonthAmount() {
    final provider = context.read<BusinessProvider>();
    final prevMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
      1,
    );
    final existing = provider.deemedPurchases
        .where(
          (d) =>
              d.yearMonth.year == prevMonth.year &&
              d.yearMonth.month == prevMonth.month,
        )
        .toList();
    return existing.isNotEmpty ? existing.first.amount : null;
  }

  /// 간단 절감 효과 추정치 (한도 미반영, 공제율만 적용)
  int _estimateVatSavings(BusinessProvider provider, int amount) {
    final now = DateTime.now();
    final business = provider.business;
    final taxBase = provider.vatBreakdown.taxBase;

    final isRestaurant =
        business.businessType == 'restaurant' ||
        business.businessType == 'cafe';
    if (!isRestaurant) {
      return (amount * 2 / 102).round();
    }

    final specialEnd = DateTime(2026, 12, 31, 23, 59, 59);
    final useNineOver109 = !now.isAfter(specialEnd) && taxBase <= 200000000;
    return useNineOver109
        ? (amount * 9 / 109).round()
        : (amount * 8 / 108).round();
  }

  void _onSave() {
    if (_selectedAmount == null || _selectedAmount == 0) {
      // Allow saving 0
      if (_selectedAmount == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('금액을 선택해 주세요')));
        return;
      }
    }

    final purchase = DeemedPurchase(
      yearMonth: _selectedMonth,
      amount: _selectedAmount!,
    );

    context.read<BusinessProvider>().addDeemedPurchase(purchase);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('저장되었습니다')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final prevAmount = _getPreviousMonthAmount();
    final vatSavings = _selectedAmount != null && _selectedAmount! > 0
        ? _estimateVatSavings(provider, _selectedAmount!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('의제매입 입력'),
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
            Text(
              '면세 식재료 매입액을\n입력해 주세요',
              style: AppTypography.textTheme.titleMedium,
            ),
            const SizedBox(height: 20),

            // Month selector
            Text('월 선택', style: AppTypography.textTheme.titleSmall),
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

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedMonth = month);
                      _loadExistingData();
                      setState(() {});
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
                      child: Text(
                        Formatters.formatMonth(month),
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppColors.textOnPrimary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Amount preset picker
            PresetAmountPicker(
              label: '금액 프리셋',
              presets: const [0, 1000000, 3000000, 5000000],
              selectedAmount: _selectedAmount,
              onSelected: (amount) => setState(() => _selectedAmount = amount),
              referenceText: prevAmount != null
                  ? '${Formatters.formatMonth(DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1))}: ${Formatters.toManWonWithUnit(prevAmount)}'
                  : null,
              referenceAmount: prevAmount,
            ),
            const SizedBox(height: 24),

            // VAT savings feedback
            if (vatSavings != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('\u{1F4C9}', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '부가세 약 ${Formatters.toManWonWithUnit(vatSavings)} 절감 효과!',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
