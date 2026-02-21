import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('개인정보 처리방침'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '개인정보 처리방침',
                style: AppTypography.textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              _buildSection(
                '1. 개인정보의 수집 및 이용 목적',
                '세금레이더는 사용자의 세금 예측을 위해 매출, 경비, 사업자 정보를 처리합니다. '
                    '모든 데이터는 사용자의 기기에만 저장되며, 외부 서버로 전송되지 않습니다.',
              ),
              _buildSection(
                '2. 수집하는 개인정보 항목',
                '사업자 유형, 매출 및 경비 데이터, 인적공제 정보 (배우자, 부양가족 수). '
                    '이 정보는 기기 내부에만 저장됩니다.',
              ),
              _buildSection(
                '3. 개인정보의 보유 및 이용 기간',
                '앱이 기기에 설치되어 있는 동안 보유합니다. '
                    '앱 삭제 시 모든 데이터가 자동으로 삭제됩니다.',
              ),
              _buildSection(
                '4. 개인정보의 제3자 제공',
                '세금레이더는 사용자의 개인정보를 제3자에게 제공하지 않습니다.',
              ),
              _buildSection(
                '5. 개인정보의 파기',
                '설정 메뉴의 \'데이터 초기화\' 기능을 통해 언제든 모든 데이터를 삭제할 수 있습니다. '
                    '앱 삭제 시에도 모든 데이터가 자동으로 파기됩니다.',
              ),
              _buildSection(
                '6. 이용자의 권리',
                '사용자는 언제든 앱 내에서 자신의 데이터를 조회, 수정, 삭제할 수 있습니다.',
              ),
              _buildSection(
                '7. 개인정보 보호책임자',
                '이메일: support@taxradar.kr',
              ),
              _buildSection(
                '8. 시행일',
                '본 개인정보 처리방침은 2025년 1월 1일부터 시행됩니다.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
