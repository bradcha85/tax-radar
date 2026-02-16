import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/business_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/weather_icon.dart';
import '../../widgets/range_bar.dart';
import '../../widgets/notion_card.dart';

class FirstResultScreen extends StatelessWidget {
  const FirstResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final prediction = provider.vatPrediction;
    final weather = provider.taxWeather;
    final accuracy = provider.accuracyScore;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Weather icon
                    WeatherIcon(weather: weather),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      '부가세 예상',
                      style: AppTypography.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Range bar
                    RangeBar(
                      minValue: prediction.predictedMin,
                      maxValue: prediction.predictedMax,
                      absoluteMax: prediction.predictedMax > 0
                          ? (prediction.predictedMax * 1.5).round()
                          : 10000000,
                    ),

                    const SizedBox(height: 16),

                    // Amount text
                    Text(
                      '${Formatters.toManWonWithUnit(prediction.predictedMin)} ~ ${Formatters.toManWonWithUnit(prediction.predictedMax)}',
                      style: AppTypography.amountLarge,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    const Divider(color: AppColors.divider, height: 1),

                    const SizedBox(height: 20),

                    // Accuracy section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '정확도 ',
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$accuracy%',
                          style: AppTypography.textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: accuracy / 100,
                          backgroundColor: AppColors.borderLight,
                          color: AppColors.primary,
                          minHeight: 6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info card
                    NotionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\u{1F4A1} 범위가 넓어요.',
                            style: AppTypography.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '지출 자료를 추가하면 좁아져요',
                            style:
                                AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          provider.completeOnboarding();
                          context.go('/data');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '지금 추가하기',
                          style:
                              AppTypography.textTheme.titleMedium?.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          provider.completeOnboarding();
                          context.go('/radar');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '나중에 할게요',
                          style:
                              AppTypography.textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
