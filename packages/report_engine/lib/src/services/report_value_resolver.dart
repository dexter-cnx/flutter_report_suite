class ReportValueResolver {
  const ReportValueResolver();

  static final RegExp _placeholderPattern = RegExp(r'\{\{\s*([^{}]+?)\s*\}\}');

  dynamic resolve(String? expression, Map<String, dynamic> data) {
    if (expression == null) return '';

    final path = expression.replaceAll('{{', '').replaceAll('}}', '').trim();
    if (path.isEmpty) return '';

    dynamic current = data;
    for (final segment in path.split('.')) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
        continue;
      }
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
        continue;
      }
      if (current is List) {
        final index = int.tryParse(segment);
        if (index == null || index < 0 || index >= current.length) return '';
        current = current[index];
        continue;
      }
      return '';
    }
    return current ?? '';
  }

  String resolveText(String? expression, Map<String, dynamic> data) {
    if (expression == null || expression.isEmpty) return '';

    final matches =
        _placeholderPattern.allMatches(expression).toList(growable: false);
    if (matches.isEmpty) {
      return resolve(expression, data).toString();
    }

    if (matches.length == 1 && matches.single.group(0) == expression.trim()) {
      return resolve(matches.single.group(1), data).toString();
    }

    return expression.replaceAllMapped(
      _placeholderPattern,
      (match) => resolve(match.group(1), data).toString(),
    );
  }
}
