import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'notion_card.dart';

class AccuracyGauge extends StatelessWidget {
  final int overallPercent;
  final int salesPercent;
  final int expensePercent;
  final int deemedPercent;
  final int freshnessPercent;
  final Function(String type)? onItemTap;

  const AccuracyGauge({
    super.key,
    required this.overallPercent,
    required this.salesPercent,
    required this.expensePercent,
    required this.deemedPercent,
    required this.freshnessPercent,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return NotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall accuracy
          Row(
            children: [
              Text('정확도', style: AppTypography.textTheme.titleMedium),
              const SizedBox(width: 8),
              Text(
                '$overallPercent%',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: _getAccuracyColor(overallPercent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overallPercent / 100,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getAccuracyColor(overallPercent),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          // Sub-items
          _buildItem('📊', '매출', salesPercent, 'sales'),
          const SizedBox(height: 10),
          _buildItem('💳', '지출', expensePercent, 'expense'),
          const SizedBox(height: 10),
          _buildItem('🥬', '의제매입', deemedPercent, 'deemed'),
          const SizedBox(height: 10),
          _buildItem('📋', '최신성', freshnessPercent, 'freshness'),
        ],
      ),
    );
  }

  Widget _buildItem(String emoji, String label, int percent, String type) {
    final isTappable = percent == 0 && onItemTap != null;

    final row = Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(label, style: AppTypography.textTheme.bodyMedium),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                percent > 0 ? AppColors.primary : AppColors.borderLight,
              ),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: percent > 0
              ? Text(
                  '$percent%',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                )
              : Text(
                  '입력하기',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.right,
                ),
        ),
      ],
    );

    if (isTappable) {
      return GestureDetector(
        onTap: () => onItemTap!(type),
        behavior: HitTestBehavior.opaque,
        child: row,
      );
    }
    return row;
  }

  Color _getAccuracyColor(int percent) {
    if (percent >= 70) return AppColors.success;
    if (percent >= 40) return AppColors.warning;
    return AppColors.danger;
  }
}
