import 'package:flutter/material.dart';
import '../data/glossary_terms.dart';
import '../models/glossary_term.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class TermHelpHeader extends StatelessWidget {
  final String title;
  final String termId;
  final String? statusLabel;
  final ValueChanged<String>? onTermViewed;

  const TermHelpHeader({
    super.key,
    required this.title,
    required this.termId,
    this.statusLabel,
    this.onTermViewed,
  });

  @override
  Widget build(BuildContext context) {
    final term = kGlossaryTermMap[termId];

    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: AppTypography.textTheme.titleSmall,
          ),
        ),
        if (statusLabel != null) ...[
          const SizedBox(width: 8),
          _StatusChip(label: statusLabel!),
        ],
        if (term != null) ...[
          const SizedBox(width: 8),
          _TinyTextButton(
            text: '?',
            onTap: () {
              onTermViewed?.call(term.id);
              showWhereToFindSheet(context, term);
            },
          ),
        ],
      ],
    );
  }
}

Future<void> showWhereToFindSheet(BuildContext context, GlossaryTerm term) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(term.title, style: AppTypography.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                term.description,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              for (final line in term.whereToFind) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('알겠어요'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
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
