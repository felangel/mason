/// Yaml Utiilities
class Yaml {
  /// Encodes a [Map<String, dynamic>] as `yaml` similar to `json.encode`.
  static String encode(Map<dynamic, dynamic> json, [int nestingLevel = 0]) {
    return json.entries
        .map((entry) => _formatEntry(entry, nestingLevel))
        .join('\n');
  }
}

String _formatEntry(MapEntry<dynamic, dynamic> entry, int nesting) {
  return '''${_indentation(nesting)}${entry.key}:${_formatValue(entry.value, nesting)}''';
}

String _formatValue(dynamic value, int nesting) {
  if (value is Map<String, dynamic>) {
    return '\n${Yaml.encode(value, nesting + 1)}';
  }
  if (value is List<dynamic>) {
    return '\n${_formatList(value, nesting + 1)}';
  }
  if (value is String) {
    if (_isMultilineString(value)) {
      return ''' |\n${value.split('\n').map((s) => '${_indentation(nesting + 1)}$s').join('\n')}''';
    }
    if (_containsSpecialCharacters(value) ||
        _containsFloatingPointPattern(value)) {
      return ' "$value"';
    }
  }
  if (value == null) {
    return '';
  }
  return ' $value';
}

String _formatList(List<dynamic> list, int nesting) {
  return list.map((dynamic value) {
    return '${_indentation(nesting)}-${_formatValue(value, nesting + 2)}';
  }).join('\n');
}

String _indentation(int nesting) => _spaces(nesting * 2);
String _spaces(int n) => ''.padRight(n, ' ');

bool _isMultilineString(String s) => s.contains('\n');

bool _containsFloatingPointPattern(String s) =>
    s.contains(RegExp(r'[0-9]\.[0-9]'));

bool _containsSpecialCharacters(String s) =>
    _specialCharacters.any((c) => s.contains(c));

final _specialCharacters = ':{}[],&*#?|-<>=!%@'.split('');
