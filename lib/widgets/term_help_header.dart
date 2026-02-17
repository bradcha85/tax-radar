import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/glossary_terms.dart';
import '../providers/business_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glossary_help_text.dart';
import 'glossary_sheet.dart';

class TermHelpHeader extends StatelessWidget {
  final String title;
  final String termId;
  final String? statusLabel;

  const TermHelpHeader({
    super.key,
    required this.title,
    required this.termId,
    this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final term = kGlossaryTermMap[termId];
    final helpMode = context.select<BusinessProvider, bool>(
      (p) => p.glossaryHelpModeEnabled,
    );

    return Row(
      children: [
        Flexible(child: Text(title, style: AppTypography.textTheme.titleSmall)),
        if (statusLabel != null) ...[
          const SizedBox(width: 8),
          _StatusChip(label: statusLabel!),
        ],
        if (term != null) ...[
          const SizedBox(width: 8),
          helpMode
              ? GlossaryHelpText(
                  label: term.title,
                  termId: term.id,
                  dense: true,
                )
              : _TinyTextButton(
                  text: '?',
                  onTap: () => showWhereToFindSheet(context, term),
                ),
        ],
      ],
    );
  }
}

class _TinyTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _TinyTextButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
          color: AppColors.surface,
        ),
        child: Text(
          text,
          style: AppTypography.textTheme.labelMedium?.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.primaryLight,
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
