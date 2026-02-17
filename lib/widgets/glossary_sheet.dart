import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/glossary_term.dart';
import '../providers/business_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

Future<void> showWhereToFindSheet(BuildContext context, GlossaryTerm term) {
  // Keep a lightweight "recent terms" trail anywhere the user opens a term.
  try {
    context.read<BusinessProvider>().markRecentGlossary(term.id);
  } catch (_) {
    // Best-effort only; sheet can still be shown even if Provider isn't found.
  }

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
