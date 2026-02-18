import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../widgets/glossary_help_text.dart';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                child: Text(
                  '데이터',
                  style: AppTypography.textTheme.headlineLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Text(
                  '데이터를 입력할수록 세금 예측이 정확해져요',
                  style: AppTypography.caption,
                ),
              ),

              // 분석 완료도 카드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _AccuracyCard(accuracy: accuracy),
              ),
              const SizedBox(height: 24),

              // 입력 항목 섹션 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  '입력 항목',
                  style: AppTypography.textTheme.titleMedium,
                ),
              ),

              // 카테고리 그룹 카드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _DataGroupCard(
                  items: [
                    _DataItem(
                      icon: Icons.trending_up_outlined,
                      activeIcon: Icons.trending_up,
                      label: '매출',
                      percent: provider.salesCompletionPercent,
                      onTap: () => context.push('/data/sales-input'),
                    ),
                    _DataItem(
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long,
                      label: '지출',
                      percent: provider.expenseCompletionPercent,
                      onTap: () => context.push('/data/expense-input'),
                    ),
                    _DataItem(
                      icon: Icons.shopping_basket_outlined,
                      activeIcon: Icons.shopping_basket,
                      label: '의제매입',
                      termId: 'V05',
                      percent: provider.deemedCompletionPercent,
                      onTap: () => context.push('/data/deemed-purchase'),
                    ),
                    _DataItem(
                      icon: Icons.history_outlined,
                      activeIcon: Icons.history,
                      label: '과거 이력',
                      percent: provider.historyCompletionPercent,
                      onTap: () => context.push('/data/history'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 정밀 종소세 카드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _PrecisionTaxCard(
                  percent: provider.precisionWizardCompletionPercent,
                  onTap: () => context.push('/precision-tax'),
                ),
              ),
              const SizedBox(height: 32),

              // 마지막 업데이트
              Center(
                child: Text(
                  '마지막 업데이트: ${_formatRelativeTime(provider.lastUpdate)}',
                  style: AppTypography.caption,
                ),
              ),
              const SizedBox(height: 24),
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

// ───────────────────────────────────────────
// 분석 완료도 카드
// ───────────────────────────────────────────
class _AccuracyCard extends StatelessWidget {
  final int accuracy;
  const _AccuracyCard({required this.accuracy});

  Color get _barColor {
    if (accuracy >= 70) return AppColors.success;
    if (accuracy >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  String get _message {
    if (accuracy >= 70) return '세금 예측이 충분히 정확해요 ✓';
    if (accuracy >= 40) return '조금 더 입력하면 예측이 훨씬 정확해져요';
    return '기본 데이터를 입력하면 세금 예측이 시작돼요';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('분석 완료도', style: AppTypography.caption),
              Text(
                '$accuracy%',
                style: AppTypography.numDisplayMedium.copyWith(
                  color: _barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: accuracy / 100,
              minHeight: 8,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(_message, style: AppTypography.caption),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// 데이터 아이템 모델
// ───────────────────────────────────────────
class _DataItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? termId;
  final int percent;
  final VoidCallback onTap;

  const _DataItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.termId,
    required this.percent,
    required this.onTap,
  });
}

// ───────────────────────────────────────────
// 그룹 카드 (HTML의 breakdown card 패턴)
// ───────────────────────────────────────────
class _DataGroupCard extends StatelessWidget {
  final List<_DataItem> items;
  const _DataGroupCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              _DataRowTile(item: item),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderLight,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ───────────────────────────────────────────
// 개별 행 타일
// ───────────────────────────────────────────
class _DataRowTile extends StatelessWidget {
  final _DataItem item;
  const _DataRowTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDone = item.percent > 0;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // 아이콘 컨테이너
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDone ? AppColors.primaryLight : AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDone ? item.activeIcon : item.icon,
                size: 20,
                color: isDone ? AppColors.primary : AppColors.textHint,
              ),
            ),
            const SizedBox(width: 14),

            // 라벨
            Expanded(
              child: item.termId == null
                  ? Text(
                      item.label,
                      style: AppTypography.textTheme.titleSmall,
                    )
                  : GlossaryHelpText(
                      label: item.label,
                      termId: item.termId!,
                      style: AppTypography.textTheme.titleSmall,
                      dense: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
            ),

            // 완료 상태 배지
            if (isDone)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${item.percent}%',
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Text(
                '미입력',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.textHint,
                ),
              ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────
// 정밀 종소세 카드 (accent light 배경)
// ───────────────────────────────────────────
class _PrecisionTaxCard extends StatelessWidget {
  final int percent;
  final VoidCallback onTap;
  const _PrecisionTaxCard({required this.percent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calculate_outlined,
                size: 22,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 14),

            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlossaryHelpText(
                    label: '정밀 종소세',
                    termId: 'T01',
                    style: AppTypography.textTheme.titleSmall,
                    dense: true,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '신고급 계산 Stepper 시작/이어하기',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),

            // 진행률 배지
            if (percent > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percent%',
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
