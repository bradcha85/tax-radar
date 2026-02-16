import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../widgets/notion_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _taxSeasonNotif = true;
  bool _monthlyInputNotif = true;

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
    if (profile.childrenCount > 0) {
      parts.add('자녀 ${profile.childrenCount}명');
    }
    if (profile.supportsParents) parts.add('부모님');
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final business = provider.business;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('설정', style: AppTypography.textTheme.headlineMedium),
              const SizedBox(height: 20),

              // Business info section
              _SectionHeader(title: '사업장 정보'),
              const SizedBox(height: 8),
              NotionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: '업종',
                      value: _businessTypeLabel(business.businessType),
                    ),
                    const Divider(height: 20, color: AppColors.borderLight),
                    _InfoRow(
                      label: '과세유형',
                      value: _taxTypeLabel(business.taxType),
                    ),
                    const Divider(height: 20, color: AppColors.borderLight),
                    _InfoRow(
                      label: 'VAT 포함',
                      value: business.vatInclusive ? '예' : '아니요',
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.push('/onboarding/business-info'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                        child: Text(
                          '수정',
                          style:
                              AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Dependents section
              _SectionHeader(title: '부양가족 정보'),
              const SizedBox(height: 8),
              NotionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dependentsLabel(provider),
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/data/history'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                        child: Text(
                          '수정',
                          style:
                              AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notification section
              _SectionHeader(title: '알림 설정'),
              const SizedBox(height: 8),
              NotionCard(
                child: Column(
                  children: [
                    _ToggleRow(
                      label: '세금 시즌 알림',
                      value: _taxSeasonNotif,
                      onChanged: (v) =>
                          setState(() => _taxSeasonNotif = v),
                    ),
                    const Divider(height: 20, color: AppColors.borderLight),
                    _ToggleRow(
                      label: '월별 입력 알림',
                      value: _monthlyInputNotif,
                      onChanged: (v) =>
                          setState(() => _monthlyInputNotif = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // App info section
              _SectionHeader(title: '앱 정보'),
              const SizedBox(height: 8),
              NotionCard(
                child: _InfoRow(label: '버전', value: '1.0.0'),
              ),
              const SizedBox(height: 24),

              // Logout button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    context.go('/splash');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '로그아웃',
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.textTheme.titleSmall?.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
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
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.textTheme.bodyMedium),
        SizedBox(
          height: 24,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
