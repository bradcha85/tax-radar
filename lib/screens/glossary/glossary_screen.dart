import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/glossary_terms.dart';
import '../../models/glossary_term.dart';
import '../../providers/business_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/notion_card.dart';
import '../../widgets/glossary_sheet.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _category = '전체';

  List<String> get _categories {
    final set = <String>{'전체', ...kGlossaryTerms.map((term) => term.category)};
    final list = set.toList();
    list.sort();
    if (list.remove('전체')) {
      list.insert(0, '전체');
    }
    return list;
  }

  List<GlossaryTerm> _filteredTerms() {
    return kGlossaryTerms.where((term) {
      if (_category != '전체' && term.category != _category) return false;
      if (_query.trim().isEmpty) return true;
      final q = _query.trim().toLowerCase();
      return term.id.toLowerCase().contains(q) ||
          term.title.toLowerCase().contains(q) ||
          term.description.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final favoriteIds = provider.favoriteGlossaryIds;
    final recentIds = provider.recentGlossaryIds;
    final filtered = _filteredTerms();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('용어 사전'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: '용어/ID 검색 (예: T18, 원천징수)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == _category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = category),
                    selectedColor: AppColors.primaryLight,
                    labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  if (favoriteIds.isNotEmpty) ...[
                    Text('즐겨찾기', style: AppTypography.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: favoriteIds
                          .map((id) => kGlossaryTermMap[id])
                          .whereType<GlossaryTerm>()
                          .map(
                            (term) => _QuickTermChip(
                              term: term,
                              onTap: () => _openTerm(context, term),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (recentIds.isNotEmpty) ...[
                    Text('최근 본 용어', style: AppTypography.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recentIds
                          .take(8)
                          .map((id) => kGlossaryTermMap[id])
                          .whereType<GlossaryTerm>()
                          .map(
                            (term) => _QuickTermChip(
                              term: term,
                              onTap: () => _openTerm(context, term),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    '용어 목록 (${filtered.length})',
                    style: AppTypography.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    NotionCard(
                      child: Text(
                        '검색 결과가 없습니다.',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ...filtered.map(
                    (term) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NotionCard(
                        onTap: () => _openTerm(context, term),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${term.id} · ${term.title}',
                                    style: AppTypography.textTheme.titleSmall,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => context
                                      .read<BusinessProvider>()
                                      .toggleFavoriteGlossary(term.id),
                                  icon: Icon(
                                    favoriteIds.contains(term.id)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: favoriteIds.contains(term.id)
                                        ? AppColors.warning
                                        : AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              term.description,
                              style: AppTypography.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTerm(BuildContext context, GlossaryTerm term) {
    showWhereToFindSheet(context, term);
  }
}

class _QuickTermChip extends StatelessWidget {
  final GlossaryTerm term;
  final VoidCallback onTap;

  const _QuickTermChip({required this.term, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('${term.id} ${term.title}'),
      onPressed: onTap,
      side: const BorderSide(color: AppColors.border),
      backgroundColor: AppColors.surface,
      labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
