import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/chip_selector.dart';

class HistoryInputScreen extends StatefulWidget {
  const HistoryInputScreen({super.key});

  @override
  State<HistoryInputScreen> createState() => _HistoryInputScreenState();
}

class _HistoryInputScreenState extends State<HistoryInputScreen> {
  final _vatController = TextEditingController();
  final _umbrellaController = TextEditingController();

  String _bookkeeping = 'unknown'; // 'yes', 'no', 'unknown'

  // Dependents
  bool _hasSpouse = false;
  int _childrenCount = 0;
  bool _supportsParents = false;

  // Yellow umbrella
  bool _yellowUmbrella = false;

  @override
  void initState() {
    super.initState();
    _loadFromProfile();
  }

  void _loadFromProfile() {
    final profile = context.read<BusinessProvider>().profile;

    if (profile.previousVatAmount != null) {
      _vatController.text = Formatters.formatWon(profile.previousVatAmount!);
    }
    _bookkeeping = profile.hasBookkeeping ? 'yes' : 'unknown';
    _hasSpouse = profile.hasSpouse;
    _childrenCount = profile.childrenCount;
    _supportsParents = profile.supportsParents;
    _yellowUmbrella = profile.yellowUmbrella;
    if (profile.yellowUmbrellaMonthly != null) {
      _umbrellaController.text =
          Formatters.formatWon(profile.yellowUmbrellaMonthly!);
    }
  }

  void _onSave() {
    final vatText = _vatController.text.replaceAll(',', '');
    final vatAmount = int.tryParse(vatText);

    final umbrellaText = _umbrellaController.text.replaceAll(',', '');
    final umbrellaMonthly =
        _yellowUmbrella ? int.tryParse(umbrellaText) : null;

    context.read<BusinessProvider>().updateProfile(
          previousVatAmount: vatAmount,
          hasBookkeeping: _bookkeeping == 'yes',
          hasSpouse: _hasSpouse,
          childrenCount: _childrenCount,
          supportsParents: _supportsParents,
          yellowUmbrella: _yellowUmbrella,
          yellowUmbrellaMonthly: umbrellaMonthly,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장되었습니다')),
    );
    context.pop();
  }

  @override
  void dispose() {
    _vatController.dispose();
    _umbrellaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('과거 이력 \u00B7 개인정보'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Previous VAT amount
            Text('직전 부가세 납부세액',
                style: AppTypography.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _vatController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorFormatter(),
              ],
              style: AppTypography.amountSmall,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: AppTypography.hint.copyWith(fontSize: 16),
                suffixText: '원',
                suffixStyle: AppTypography.textTheme.bodyMedium,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _HintText(text: '알면 범위가 좁아져요'),
            const SizedBox(height: 24),

            // Bookkeeping
            Text('장부(기장) 하고 계세요?',
                style: AppTypography.textTheme.titleSmall),
            const SizedBox(height: 12),
            ChipSelector(
              options: const [
                ChipOption(label: '네', value: 'yes'),
                ChipOption(label: '아니요', value: 'no'),
                ChipOption(label: '모르겠음', value: 'unknown'),
              ],
              selectedValue: _bookkeeping,
              onSelected: (v) => setState(() => _bookkeeping = v),
            ),
            const SizedBox(height: 24),

            // Dependents
            Text('부양가족', style: AppTypography.textTheme.titleSmall),
            const SizedBox(height: 12),
            _DependentCheckbox(
              label: '본인 (기본)',
              value: true,
              enabled: false,
              onChanged: (_) {},
            ),
            _DependentCheckbox(
              label: '배우자',
              value: _hasSpouse,
              onChanged: (v) => setState(() => _hasSpouse = v ?? false),
            ),
            _DependentCheckbox(
              label: '자녀 1명',
              value: _childrenCount >= 1,
              onChanged: (v) {
                setState(() {
                  if (v == true && _childrenCount < 1) {
                    _childrenCount = 1;
                  } else if (v == false && _childrenCount == 1) {
                    _childrenCount = 0;
                  }
                });
              },
            ),
            _DependentCheckbox(
              label: '자녀 2명 이상',
              value: _childrenCount >= 2,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _childrenCount = 2;
                  } else if (v == false) {
                    _childrenCount = _childrenCount >= 2 ? 1 : _childrenCount;
                  }
                });
              },
            ),
            _DependentCheckbox(
              label: '부모님',
              value: _supportsParents,
              onChanged: (v) =>
                  setState(() => _supportsParents = v ?? false),
            ),
            const SizedBox(height: 24),

            // Yellow umbrella
            Text('노란우산공제', style: AppTypography.textTheme.titleSmall),
            const SizedBox(height: 12),
            ChipSelector(
              options: const [
                ChipOption(label: '미가입', value: 'no'),
                ChipOption(label: '가입', value: 'yes'),
              ],
              selectedValue: _yellowUmbrella ? 'yes' : 'no',
              onSelected: (v) =>
                  setState(() => _yellowUmbrella = v == 'yes'),
            ),
            if (_yellowUmbrella) ...[
              const SizedBox(height: 12),
              Text('월 납입액', style: AppTypography.textTheme.bodyMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _umbrellaController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ThousandsSeparatorFormatter(),
                ],
                style: AppTypography.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: AppTypography.hint,
                  suffixText: '원',
                  suffixStyle: AppTypography.textTheme.bodyMedium,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Hint
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('\u{1F4A1}', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '몰라도 괜찮아요.\n알면 범위가 좁아져요',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '저장하기',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  final String text;
  const _HintText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Text('\u{1F4A1}', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(text, style: AppTypography.hint),
        ],
      ),
    );
  }
}

class _DependentCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  const _DependentCheckbox({
    required this.label,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: AppColors.border, width: 1.5),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final digits = newValue.text.replaceAll(',', '');
    final number = int.tryParse(digits);
    if (number == null) return oldValue;

    final formatted = Formatters.formatWon(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
