class GlossaryTerm {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> whereToFind;

  const GlossaryTerm({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.whereToFind,
  });
}
