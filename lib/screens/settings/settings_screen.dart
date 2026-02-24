import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsBusy = false;

  String _businessTypeLabel(String type) {
    switch (type) {
      case 'restaurant':
        return '음식점';
      case 'cafe':
        return '카페';
      default:
        return '기타';
    }
  }

  String _taxTypeLabel(String type) {
    switch (type) {
      case 'general':
        return '일반과세자';
      case 'simplified':
        return '간이과세자';
      default:
        return '미정';
    }
  }

  String _dependentsLabel(BusinessProvider provider) {
    final profile = provider.profile;
    final parts = <String>['본인'];
    if (profile.hasSpouse) parts.add('배우자');
    if (profile.childrenCount > 0) parts.add('자녀 ${profile.childrenCount}명');
    if (profile.supportsParents) parts.add('부모님');
    return parts.join(', ');
  }

  Future<void> _toggleWeeklyReminder(bool enabled) async {
    if (_notificationsBusy) return;
    setState(() => _notificationsBusy = true);

    final provider = context.read<BusinessProvider>();
    await NotificationService.initialize();
    if (!mounted) return;

    if (enabled) {
      final granted = await NotificationService.requestPermissionIfNeeded();
      if (!granted) {
        await NotificationService.cancelWeeklyReminder();
        provider.setWeeklyReminderEnabled(false);
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        if (mounted) setState(() => _notificationsBusy = false);
        return;
      }

      await NotificationService.scheduleWeeklyReminder(
        weekday: DateTime.monday,
        hour: 15,
        minute: 0,
      );
      provider.setWeeklyReminderEnabled(true);
    } else {
      await NotificationService.cancelWeeklyReminder();
      provider.setWeeklyReminderEnabled(false);
    }

    if (mounted) setState(() => _notificationsBusy = false);
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('알림 권한이 필요해요', style: AppTypography.textTheme.titleMedium),
        content: Text(
          '알림이 꺼져 있어서 리마인드를 켤 수 없어요.\n\n'
          '휴대폰 설정에서 세금레이더 알림을 허용한 뒤 다시 시도해 주세요.',
          style: AppTypography.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '확인',
              style: AppTypography.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('데이터 초기화', style: AppTypography.textTheme.titleMedium),
        content: Text(
          '모든 데이터가 삭제되고 처음 화면으로 돌아갑니다. 계속하시겠어요?',
          style: AppTypography.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '취소',
              style: AppTypography.textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BusinessProvider>().resetAllData();
              if (context.mounted) context.go('/splash');
            },
            child: Text(
              '초기화',
              style: AppTypography.textTheme.labelLarge?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final business = provider.business;

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
                child: Text('설정', style: AppTypography.textTheme.headlineLarge),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Text(
                  '사업장 정보 및 앱 환경을 관리해요',
                  style: AppTypography.caption,
                ),
              ),

              // ── 사업장 정보 ──────────────────────────────
              _SectionLabel(title: '사업장 정보'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _GroupCard(
                  children: [
                    _InfoRow(
                      label: '업종',
                      value: _businessTypeLabel(business.businessType),
                    ),
                    const _CardDivider(),
                    _InfoRow(
                      label: '과세유형',
                      value: _taxTypeLabel(business.taxType),
                      valueColor: AppColors.primary,
                    ),
                    const _CardDivider(),
                    _InfoRow(
                      label: 'VAT 포함',
                      value: business.vatInclusive ? '예' : '아니요',
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.push('/settings/business-info'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '수정',
                          style: AppTypography.textTheme.labelLarge
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 부양가족 정보 ─────────────────────────────
              _SectionLabel(title: '부양가족 정보'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _GroupCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dependentsLabel(provider),
                            style: AppTypography.textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () => context.push('/data/history'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '수정',
                              style: AppTypography.textTheme.labelLarge
                                  ?.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 앱 설정 ──────────────────────────────────
              _SectionLabel(title: '앱 설정'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _GroupCard(
                  children: [
                    // 상세설명 모드
                    _ToggleRow(
                      label: '상세설명 모드',
                      sub: '세금 용어에 ⓘ 아이콘을 표시해요',
                      value: provider.glossaryHelpModeEnabled,
                      onChanged: (v) => provider.setGlossaryHelpModeEnabled(v),
                    ),
                    const _CardDivider(),
                    // 용어 사전
                    _NavRow(
                      label: '용어 사전',
                      onTap: () => context.push('/glossary'),
                    ),
                    const _CardDivider(),
                    // 세금 시뮬레이터
                    _NavRow(
                      label: '세금 시뮬레이터',
                      sub: '예상 세액 미리보기',
                      onTap: () => context.push('/simulator'),
                    ),
                    const _CardDivider(),
                    // 주간 입력 리마인드
                    _ToggleRow(
                      label: '주간 입력 알림',
                      sub: '매주 월요일 오후 3시에 알려드려요',
                      value: provider.weeklyReminderEnabled,
                      enabled: !_notificationsBusy,
                      onChanged: _toggleWeeklyReminder,
                    ),
                    const _CardDivider(),
                    // 데이터 초기화
                    _DangerRow(
                      label: '데이터 초기화',
                      onTap: () => _showResetDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 정보 ─────────────────────────────────────
              _SectionLabel(title: '정보'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _GroupCard(
                  children: [
                    _InfoRow(label: '앱 버전', value: '1.0.0'),
                    const _CardDivider(),
                    _NavRow(
                      label: '개인정보 처리방침',
                      onTap: () => context.push('/privacy-policy'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // 푸터
              Center(
                child: Column(
                  children: [
                    Text(
                      'Copyright © 2024 TaxFintech Corp.',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All rights reserved.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 섹션 레이블
// ─────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: AppTypography.textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 그룹 카드 (HTML breakdown card 패턴)
// ─────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 카드 내부 구분선
// ─────────────────────────────────────────────────────
class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderLight,
    );
  }
}

// ─────────────────────────────────────────────────────
// 정보 행 (label | value)
// ─────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 네비게이션 행 (label [sub] | chevron)
// ─────────────────────────────────────────────────────
class _NavRow extends StatelessWidget {
  final String label;
  final String? sub;
  final VoidCallback onTap;

  const _NavRow({required this.label, this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(sub!, style: AppTypography.caption),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 토글 행 (label [sub] | switch)
// ─────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _ToggleRow({
    required this.label,
    this.sub,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub!, style: AppTypography.caption),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 28,
            child: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeTrackColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 위험 행 (red label | trash icon)
// ─────────────────────────────────────────────────────
class _DangerRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}
