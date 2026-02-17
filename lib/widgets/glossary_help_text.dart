import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/glossary_terms.dart';
import '../providers/business_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glossary_sheet.dart';

class GlossaryHelpText extends StatelessWidget {
  final String label;
  final String termId;
  final TextStyle? style;
  final bool dense;
  final String? chipLabel;
  final TextOverflow? overflow;
  final int? maxLines;

  const GlossaryHelpText({
    super.key,
    required this.label,
    required this.termId,
    this.style,
    this.dense = false,
    this.chipLabel,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final term = kGlossaryTermMap[termId];
    if (term == null) {
      return Text(label, style: style, overflow: overflow, maxLines: maxLines);
    }

    final helpMode = context.select<BusinessProvider, bool>(
      (p) => p.glossaryHelpModeEnabled,
    );
    if (!helpMode) {
      return Text(label, style: style, overflow: overflow, maxLines: maxLines);
    }

    final text = '#${chipLabel ?? label}';
    return _HashtagChip(
      label: text,
      dense: dense,
      onTap: () => showWhereToFindSheet(context, term),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final String label;
  final bool dense;
  final VoidCallback onTap;

  const _HashtagChip({
    required this.label,
    required this.dense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final textStyle =
        (dense
                ? AppTypography.textTheme.labelMedium
                : AppTypography.textTheme.bodySmall)
            ?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              height: 1.0,
            );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Text(label, style: textStyle),
        ),
      ),
    );
  }
}
