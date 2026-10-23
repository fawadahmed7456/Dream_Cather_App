extension StringCasing on String {
  /// Title-cases each whitespace-separated word: first letter uppercased,
  /// the rest lowercased. Used for display names so "arslan", "ARSLAN" and
  /// "arslan khan" all render cleanly as "Arslan" / "Arslan Khan" regardless
  /// of how the user typed them.
  String toTitleCase() {
    if (trim().isEmpty) return this;
    return split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
