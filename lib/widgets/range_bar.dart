import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';

class RangeBar extends StatelessWidget {
  final int minValue;
  final int maxValue;
  final int absoluteMin;
  final int absoluteMax;
  final Color color;
  final double height;

  const RangeBar({
    super.key,
    required this.minValue,
    required this.maxValue,
    this.absoluteMin = 0,
    required this.absoluteMax,
    this.color = AppColors.primary,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final totalRange = absoluteMax - absoluteMin;
    final startFraction =
        totalRange > 0 ? (minValue - absoluteMin) / totalRange : 0.0;
    final endFraction =
        totalRange > 0 ? (maxValue - absoluteMin) / totalRange : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final left = startFraction * barWidth;
            final filledWidth = (endFraction - startFraction) * barWidth;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(height / 2),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: left.clamp(0, barWidth),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      width: filledWidth.clamp(0, barWidth - left.clamp(0, barWidth)),
                      height: height,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          '${Formatters.toManWonWithUnit(minValue)} ─── ${Formatters.toManWonWithUnit(maxValue)}',
          style: AppTypography.caption,
        ),
      ],
    );
  }
}
