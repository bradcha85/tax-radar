import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../models/monthly_expenses.dart';
import '../../utils/formatters.dart';
import '../../widgets/chip_selector.dart';

class ExpenseInputScreen extends StatefulWidget {
  const ExpenseInputScreen({super.key});

  @override
  State<ExpenseInputScreen> createState() => _ExpenseInputScreenState();
}

class _ExpenseInputScreenState extends State<ExpenseInputScreen> {
  late List<DateTime> _months;
  late DateTime _selectedMonth;
  final _totalController = TextEditingController();
  String _taxableRatio = '90'; // '90', '50', '10'

  @override
  void initState() {
    super.initState();
    _months = _getLast6Months();
    _selectedMonth = _months.last;
  }

  List<DateTime> _getLast6Months() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      return DateTime(now.year, now.month - 5 + i, 1);
    });
  }

  int get _totalExpenses {
    final text = _totalController.text.replaceAll(',', '');
    return int.tryParse(text) ?? 0;
  }

  int get _taxableExpenses {
    final ratio = int.tryParse(_taxableRatio) ?? 90;
    return (_totalExpenses * ratio / 100).round();
  }

  void _onSave() {
    if (_totalExpenses <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지출 금액을 입력해 주세요')));
      return;
    }

    final expenses = MonthlyExpenses(
      yearMonth: _selectedMonth,
      totalExpenses: _totalExpenses,
      taxableExpenses: _taxableExpenses,
    );

    context.read<BusinessProvider>().addExpenses(expenses);

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
        title: const Text('지출 입력'),
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
                    onTap: () => setState(() => _selectedMonth = month),
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

            // Total expenses
            Text('총 지출', style: AppTypography.textTheme.titleSmall),
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

            // Taxable ratio
            Text('과세 매입 비율', style: AppTypography.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('부가세 붙는 지출이 대부분인가요?', style: AppTypography.caption),
            const SizedBox(height: 12),
            ChipSelector(
              options: const [
                ChipOption(label: '대부분 붙음', value: '90', description: '90%'),
                ChipOption(label: '반반', value: '50', description: '50%'),
                ChipOption(label: '거의 안 붙음', value: '10', description: '10%'),
              ],
              selectedValue: _taxableRatio,
              onSelected: (v) => setState(() => _taxableRatio = v),
            ),
            const SizedBox(height: 16),

            // Auto-calculated taxable amount
            if (_totalExpenses > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('과세 매입액', style: AppTypography.textTheme.bodyMedium),
                    Text(
                      Formatters.toManWonWithUnit(_taxableExpenses),
                      style: AppTypography.textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Hint
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('\u{1F4A1}', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '몰라도 괜찮아요.\n업종 평균으로 계산해요.',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
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
