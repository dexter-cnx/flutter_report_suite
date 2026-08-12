class ReportValueResolver {
  const ReportValueResolver();

  dynamic resolve(String? expression, Map<String, dynamic> data) {
    if (expression == null) return '';

    final path = expression
        .replaceAll('{{', '')
        .replaceAll('}}', '')
        .trim();
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
    return resolve(expression, data).toString();
  }
}
