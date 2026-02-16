import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';

class PresetAmountPicker extends StatefulWidget {
  final List<int> presets;
  final int? selectedAmount;
  final Function(int amount) onSelected;
  final bool showCustomInput;
  final String? label;
  final String? referenceText;
  final int? referenceAmount;

  const PresetAmountPicker({
    super.key,
    required this.presets,
    this.selectedAmount,
    required this.onSelected,
    this.showCustomInput = true,
    this.label,
    this.referenceText,
    this.referenceAmount,
  });

  @override
  State<PresetAmountPicker> createState() => _PresetAmountPickerState();
}

class _PresetAmountPickerState extends State<PresetAmountPicker> {
  bool _showTextField = false;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isPreset(int amount) => widget.presets.contains(amount);

  bool get _isCustomSelected =>
      widget.selectedAmount != null &&
      !_isPreset(widget.selectedAmount!) &&
      widget.selectedAmount != widget.referenceAmount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTypography.textTheme.titleMedium),
          const SizedBox(height: 12),
        ],
        if (widget.referenceText != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.referenceText!,
                    style: AppTypography.textTheme.bodyMedium,
                  ),
                ),
                if (widget.referenceAmount != null)
                  GestureDetector(
                    onTap: () {
                      setState(() => _showTextField = false);
                      widget.onSelected(widget.referenceAmount!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.selectedAmount == widget.referenceAmount
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(
                        '그대로 쓰기',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: widget.selectedAmount == widget.referenceAmount
                              ? AppColors.textOnPrimary
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.presets.map((amount) {
              final isSelected =
                  widget.selectedAmount == amount && !_showTextField;
              final displayText = amount == 0
                  ? '0'
                  : Formatters.toManWon(amount);

              return GestureDetector(
                onTap: () {
                  setState(() => _showTextField = false);
                  widget.onSelected(amount);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    displayText,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }),
            if (widget.showCustomInput)
              GestureDetector(
                onTap: () {
                  setState(() => _showTextField = true);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _focusNode.requestFocus();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _isCustomSelected || _showTextField
                        ? AppColors.primaryLight
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isCustomSelected || _showTextField
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    '직접 입력',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: _isCustomSelected || _showTextField
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: _isCustomSelected || _showTextField
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_showTextField) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTypography.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: '금액 입력 (만원)',
              hintStyle: AppTypography.hint,
              suffixText: '만원',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
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
            onChanged: (value) {
              final manWon = int.tryParse(value);
              if (manWon != null && manWon > 0) {
                widget.onSelected(manWon * 10000);
              }
            },
            onSubmitted: (value) {
              final manWon = int.tryParse(value);
              if (manWon != null && manWon > 0) {
                widget.onSelected(manWon * 10000);
              }
            },
          ),
        ],
      ],
    );
  }
}
