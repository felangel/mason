/// A utility class for converting strings between various casing styles.
///
/// The class analyzes the given input string and provides methods to
/// retrieve the text in different casing formats like camelCase, CONSTANT_CASE,
/// snake_case, and others.
class ReCase {
  /// Constructs an instance of [ReCase] by analyzing the given [text] and
  /// grouping it into words.
  ReCase(String text) : _words = _groupIntoWords(text);

  static final _upperAlphaRegex = RegExp('[A-Z]');
  static final _symbolSet = {' ', '.', '/', '_', r'\', '-'};
  final List<String> _words;

  /// Groups the [text] into words considering different separators and casing.
  static List<String> _groupIntoWords(String text) {
    final sb = StringBuffer();
    final words = <String>[];
    final isAllCaps = text.toUpperCase() == text;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final nextChar = i + 1 == text.length ? null : text[i + 1];

      if (_symbolSet.contains(char)) {
        continue;
      }

      sb.write(char);

      final isEndOfWord = nextChar == null ||
          (_upperAlphaRegex.hasMatch(nextChar) && !isAllCaps) ||
          _symbolSet.contains(nextChar);

      if (isEndOfWord) {
        words.add(sb.toString());
        sb.clear();
      }
    }

    return words;
  }

  /// Returns the text in camelCase format.
  String get camelCase => _getCamelCase();

  /// Returns the text in CONSTANT_CASE format.
  String get constantCase => _getConstantCase();

  /// Returns the text in Sentence case format.
  String get sentenceCase => _getSentenceCase();

  /// Returns the text in snake_case format.
  String get snakeCase => _getSnakeCase();

  /// Returns the text in dot.case format.
  String get dotCase => _getSnakeCase(separator: '.');

  /// Returns the text in param-case format.
  String get paramCase => _getSnakeCase(separator: '-');

  /// Returns the text in path/case format.
  String get pathCase => _getSnakeCase(separator: '/');

  /// Returns the text in PascalCase format.
  String get pascalCase => _getPascalCase();

  /// Returns the text in Pascal.Dot.Case format.
  String get pascalDotCase => _getPascalCase(separator: '.');

  /// Returns the text in Header-Case format.
  String get headerCase => _getPascalCase(separator: '-');

  /// Returns the text in Title Case format.
  String get titleCase => _getPascalCase(separator: ' ');

  String _getCamelCase({String separator = ''}) {
    final words = _words.map(_upperCaseFirstLetter).toList();
    if (_words.isNotEmpty) {
      words[0] = words[0].toLowerCase();
    }

    return words.join(separator);
  }

  String _getConstantCase({String separator = '_'}) {
    final words = _words.map((word) => word.toUpperCase()).toList();

    return words.join(separator);
  }

  String _getPascalCase({String separator = ''}) {
    final words = _words.map(_upperCaseFirstLetter).toList();

    return words.join(separator);
  }

  String _getSentenceCase({String separator = ' '}) {
    final words = _words.map((word) => word.toLowerCase()).toList();
    if (_words.isNotEmpty) {
      words[0] = _upperCaseFirstLetter(words[0]);
    }

    return words.join(separator);
  }

  String _getSnakeCase({String separator = '_'}) {
    final words = _words.map((word) => word.toLowerCase()).toList();

    return words.join(separator);
  }

  String _upperCaseFirstLetter(String word) {
    return '''${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}''';
  }
}
