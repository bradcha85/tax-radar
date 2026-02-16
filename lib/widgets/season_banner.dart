import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';

class SeasonBanner extends StatelessWidget {
  final String taxType;
  final DateTime deadline;
  final VoidCallback? onTap;

  const SeasonBanner({
    super.key,
    required this.taxType,
    required this.deadline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    final isDanger = daysLeft <= 14;
    final bgColor = isDanger ? AppColors.dangerLight : AppColors.warningLight;
    final fgColor = isDanger ? AppColors.danger : AppColors.warning;
    final ddayText = Formatters.formatDday(deadline);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fgColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: fgColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$taxType 확정 신고 $ddayText',
                style: AppTypography.textTheme.titleSmall?.copyWith(
                  color: fgColor,
                ),
              ),
            ),
            if (onTap != null)
              Text(
                '최신 자료로 업데이트하기',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
