String stripHtmlTags(String? value) {
  if (value == null || value.isEmpty) return '';
  return value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)'),
        (match) => match.group(1) ?? '',
      )
      .replaceAll(RegExp(r'https?:\/\/\S+'), '')
      .replaceAll('**', '')
      .replaceAll('__', '')
      .replaceAll('~~', '')
      .replaceAll(RegExp(r'(^|\s)[*_`>#-]{1,3}(?=\s|$)'), ' ')
      .replaceAll(RegExp(r'-{3,}'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .trim();
}
