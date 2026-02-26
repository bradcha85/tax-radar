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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '설정',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 프로필 섹션 ──────────────────────────────
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.storefront,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '내 사업장',
                            style: AppTypography.textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              _businessTypeLabel(business.businessType),
                              style: AppTypography.textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── 사업장 관리 ──────────────────────────────
              _SectionLabel(title: '사업장 관리'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _GroupCard(
                  children: [
                    _NavRow(
                      icon: Icons.business_outlined,
                      label: '사업장 기본 정보',
                      sub:
                          '${_taxTypeLabel(business.taxType)} · VAT ${business.vatInclusive ? '포함' : '별도'}',
                      onTap: () => context.push('/settings/business-info'),
                    ),
                    const _CardDivider(),
                    _NavRow(
                      icon: Icons.family_restroom_outlined,
                      label: '부양가족 설정',
                      sub: _dependentsLabel(provider),
                      onTap: () => context.push('/data/history'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── 앱 설정 ──────────────────────────────────
              _SectionLabel(title: '앱 설정'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _GroupCard(
                  children: [
                    // 상세설명 모드
                    _ToggleRow(
                      icon: Icons.info_outline,
                      label: '상세설명 모드',
                      sub: '세금 용어에 ⓘ 아이콘을 표시해요',
                      value: provider.glossaryHelpModeEnabled,
                      onChanged: (v) => provider.setGlossaryHelpModeEnabled(v),
                    ),
                    const _CardDivider(),
                    // 주간 입력 리마인드
                    _ToggleRow(
                      icon: Icons.notifications_none_outlined,
                      label: '주간 입력 알림',
                      sub: '매주 월요일 오후 3시에 알려드려요',
                      value: provider.weeklyReminderEnabled,
                      enabled: !_notificationsBusy,
                      onChanged: _toggleWeeklyReminder,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── 유용한 기능 ────────────────────────────────
              _SectionLabel(title: '유용한 기능'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.menu_book_outlined,
                        label: '세무 용어 사전',
                        onTap: () => context.push('/glossary'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.calculate_outlined,
                        label: '세금 시뮬레이터',
                        onTap: () => context.push('/simulator'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── 지원 및 정보 ──────────────────────────────
              _SectionLabel(title: '지원 및 정보'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _GroupCard(
                  children: [
                    _NavRow(
                      icon: Icons.shield_outlined,
                      label: '개인정보 처리방침',
                      onTap: () => context.push('/privacy-policy'),
                    ),
                    const _CardDivider(),
                    _DangerRow(
                      icon: Icons.delete_outline,
                      label: '앱 데이터 초기화',
                      onTap: () => _showResetDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 푸터
              Center(
                child: Column(
                  children: [
                    Text(
                      'v1.0.0',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('TaxRadar © 2024', style: AppTypography.caption),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 액션 카드 (2단 버튼용)
// ─────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: AppTypography.textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 그룹 카드
// ─────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
    return const Padding(
      padding: EdgeInsets.only(left: 56),
      child: Divider(height: 1, thickness: 1, color: AppColors.borderLight),
    );
  }
}

// ─────────────────────────────────────────────────────
// 네비게이션 행 (icon | label [sub] | chevron)
// ─────────────────────────────────────────────────────
class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.label,
    this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
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
// 토글 행 (icon | label [sub] | switch)
// ─────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _ToggleRow({
    required this.icon,
    required this.label,
    this.sub,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 28,
            child: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: AppColors.surface,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              inactiveThumbColor: AppColors.surface,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 위험 행 (icon | red label | trash icon)
// ─────────────────────────────────────────────────────
class _DangerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DangerRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.danger, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
