import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/business_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/chip_selector.dart';

class BusinessInfoScreen extends StatefulWidget {
  const BusinessInfoScreen({super.key});

  @override
  State<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> {
  String _businessType = 'restaurant';
  String _taxType = 'general';
  String _vatInclusive = 'inclusive';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('사업장 정보', style: AppTypography.textTheme.titleLarge),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/onboarding/value'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question 1: 업종
                  _buildSectionLabel('어떤 업종이세요?'),
                  const SizedBox(height: 12),
                  ChipSelector(
                    options: const [
                      ChipOption(label: '음식점', value: 'restaurant'),
                      ChipOption(label: '카페', value: 'cafe'),
                      ChipOption(label: '기타', value: 'other'),
                    ],
                    selectedValue: _businessType,
                    onSelected: (value) {
                      setState(() => _businessType = value);
                    },
                  ),

                  const SizedBox(height: 32),

                  // Question 2: 과세유형
                  _buildSectionLabel('과세유형은?'),
                  const SizedBox(height: 12),
                  ChipSelector(
                    options: const [
                      ChipOption(label: '일반과세자', value: 'general'),
                      ChipOption(label: '간이과세자', value: 'simplified'),
                      ChipOption(label: '모르겠음', value: 'unknown'),
                    ],
                    selectedValue: _taxType,
                    onSelected: (value) {
                      setState(() => _taxType = value);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text('사업자등록증에 써있어요', style: AppTypography.hint),

                  const SizedBox(height: 32),

                  // Question 3: 부가세 포함 여부
                  _buildSectionLabel('매출 금액에 부가세가 포함되어 있나요?'),
                  const SizedBox(height: 12),
                  ChipSelector(
                    options: const [
                      ChipOption(label: '포함', value: 'inclusive'),
                      ChipOption(label: '미포함', value: 'exclusive'),
                      ChipOption(label: '모르겠음', value: 'unknown'),
                    ],
                    selectedValue: _vatInclusive,
                    onSelected: (value) {
                      setState(() => _vatInclusive = value);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text('보통 포함되어 있어요', style: AppTypography.hint),
                ],
              ),
            ),
          ),

          // Bottom button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '다음',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: AppTypography.textTheme.titleMedium);
  }

  void _onNext() {
    final provider = Provider.of<BusinessProvider>(context, listen: false);

    // Map vatInclusive string to bool
    final vatInclusiveBool = _vatInclusive == 'exclusive'
        ? false
        : true; // default to true

    provider.updateBusiness(
      businessType: _businessType,
      taxType: _taxType,
      vatInclusive: vatInclusiveBool,
    );

    context.go('/onboarding/first-sales');
  }
}
