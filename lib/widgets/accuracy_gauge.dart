import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'notion_card.dart';
import 'glossary_help_text.dart';

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
              GlossaryHelpText(
                label: '정확도',
                termId: 'T22',
                style: AppTypography.textTheme.titleMedium,
                dense: true,
              ),
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
          _buildItem(Icons.trending_up_rounded, '매출', salesPercent, 'sales'),
          const SizedBox(height: 12),
          _buildItem(
            Icons.receipt_long_outlined,
            '지출',
            expensePercent,
            'expense',
          ),
          const SizedBox(height: 12),
          _buildItem(
            Icons.storefront_outlined,
            '의제매입',
            deemedPercent,
            'deemed',
            termId: 'V05',
          ),
          const SizedBox(height: 12),
          _buildItem(
            Icons.update_rounded,
            '최신성',
            freshnessPercent,
            'freshness',
            termId: 'T29',
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    IconData icon,
    String label,
    int percent,
    String type, {
    String? termId,
  }) {
    final isTappable = percent == 0 && onItemTap != null;
    final labelWidget = termId == null
        ? Text(label, style: AppTypography.textTheme.bodyMedium)
        : GlossaryHelpText(
            label: label,
            termId: termId,
            style: AppTypography.textTheme.bodyMedium,
            dense: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          );

    final row = Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 56, maxWidth: 140),
          child: Align(alignment: Alignment.centerLeft, child: labelWidget),
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
