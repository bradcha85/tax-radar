import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ChipOption {
  final String label;
  final String value;
  final String? description;

  const ChipOption({
    required this.label,
    required this.value,
    this.description,
  });
}

class ChipSelector extends StatelessWidget {
  final List<ChipOption> options;
  final String? selectedValue;
  final Function(String value)? onSelected;
  final bool multiSelect;
  final Set<String>? selectedValues;
  final Function(Set<String>)? onMultiSelected;

  const ChipSelector({
    super.key,
    required this.options,
    this.selectedValue,
    this.onSelected,
    this.multiSelect = false,
    this.selectedValues,
    this.onMultiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = multiSelect
            ? (selectedValues?.contains(option.value) ?? false)
            : option.value == selectedValue;

        return GestureDetector(
          onTap: () {
            if (multiSelect && onMultiSelected != null) {
              final current = Set<String>.from(selectedValues ?? {});
              if (current.contains(option.value)) {
                current.remove(option.value);
              } else {
                current.add(option.value);
              }
              onMultiSelected!(current);
            } else {
              onSelected?.call(option.value);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.label,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (option.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    option.description!,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
