import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../widgets/notion_card.dart';

class DataInputScreen extends StatelessWidget {
  const DataInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final accuracy = provider.accuracyScore;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('자료함', style: AppTypography.textTheme.headlineMedium),
              const SizedBox(height: 20),

              // Overall accuracy
              NotionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '전체 정확도 $accuracy%',
                      style: AppTypography.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: accuracy / 100,
                        minHeight: 8,
                        backgroundColor: AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          accuracy >= 70
                              ? AppColors.success
                              : accuracy >= 40
                                  ? AppColors.warning
                                  : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Data category cards
              _DataCategoryCard(
                emoji: '\u{1F4CA}',
                label: '매출',
                percent: provider.salesCompletionPercent,
                onTap: () => context.push('/data/sales-input'),
              ),
              const SizedBox(height: 8),
              _DataCategoryCard(
                emoji: '\u{1F4B3}',
                label: '지출',
                percent: provider.expenseCompletionPercent,
                onTap: () => context.push('/data/expense-input'),
              ),
              const SizedBox(height: 8),
              _DataCategoryCard(
                emoji: '\u{1F96C}',
                label: '의제매입',
                percent: provider.deemedCompletionPercent,
                onTap: () => context.push('/data/deemed-purchase'),
              ),
              const SizedBox(height: 8),
              _DataCategoryCard(
                emoji: '\u{1F4CB}',
                label: '과거 이력',
                percent: provider.historyCompletionPercent,
                onTap: () => context.push('/data/history'),
              ),
              const SizedBox(height: 20),

              // Last update
              Center(
                child: Text(
                  '마지막 업데이트: ${_formatRelativeTime(provider.lastUpdate)}',
                  style: AppTypography.caption,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '없음';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '1일 전';
    if (diff.inDays < 30) return '${diff.inDays}일 전';
    return '${(diff.inDays / 30).floor()}개월 전';
  }
}

class _DataCategoryCard extends StatelessWidget {
  final String emoji;
  final String label;
  final int percent;
  final VoidCallback onTap;

  const _DataCategoryCard({
    required this.emoji,
    required this.label,
    required this.percent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NotionCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      onTap: onTap,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTypography.textTheme.titleSmall,
            ),
          ),
          if (percent > 0) ...[
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 14,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '$percent%',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: percent > 0 ? AppColors.success : AppColors.textHint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: AppColors.textHint,
            size: 20,
          ),
        ],
      ),
    );
  }
}
