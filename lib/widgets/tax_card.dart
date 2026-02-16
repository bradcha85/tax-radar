import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/tax_prediction.dart';
import '../utils/formatters.dart';
import 'notion_card.dart';
import 'range_bar.dart';

class TaxCard extends StatelessWidget {
  final String title;
  final TaxPrediction prediction;
  final String dday;
  final VoidCallback? onTap;

  const TaxCard({
    super.key,
    required this.title,
    required this.prediction,
    required this.dday,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NotionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: AppTypography.textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _ddayColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dday,
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: _ddayTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Amount
          Text(
            '${Formatters.toManWon(prediction.predictedMin)} ~ ${Formatters.toManWonWithUnit(prediction.predictedMax)}',
            style: AppTypography.amountLarge,
          ),
          const SizedBox(height: 12),
          // Range bar
          RangeBar(
            minValue: prediction.predictedMin,
            maxValue: prediction.predictedMax,
            absoluteMax: (prediction.predictedMax * 1.5).round(),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Color get _ddayColor {
    final num = _parseDday;
    if (num <= 14) return AppColors.dangerLight;
    if (num <= 30) return AppColors.warningLight;
    return AppColors.primaryLight;
  }

  Color get _ddayTextColor {
    final num = _parseDday;
    if (num <= 14) return AppColors.danger;
    if (num <= 30) return AppColors.warning;
    return AppColors.primary;
  }

  int get _parseDday {
    final match = RegExp(r'D-(\d+)').firstMatch(dday);
    if (match != null) return int.parse(match.group(1)!);
    if (dday == 'D-day') return 0;
    return 999;
  }
}
