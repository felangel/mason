import 'package:recase/recase.dart' show ReCase;

/// Built-in [String] casing extensions.
extension StringCaseExtensions on String {
  /// camelCase
  String get camelCase => ReCase(this).camelCase;

  /// CONSTANT_CASE
  String get constantCase => ReCase(this).constantCase;

  /// dot.case
  String get dotCase => ReCase(this).dotCase;

  /// Header-Case
  String get headerCase => ReCase(this).headerCase;

  /// lower case
  String get lowerCase => toLowerCase();

  /// {{ mustache case }}
  String get mustacheCase => '{{ $this }}';

  /// PascalCase
  String get pascalCase => ReCase(this).pascalCase;

  /// param-case
  String get paramCase => ReCase(this).paramCase;

  /// path/case
  String get pathCase => ReCase(this).pathCase;

  /// Sentence case
  String get sentenceCase => ReCase(this).sentenceCase;

  /// snake_case
  String get snakeCase => ReCase(this).snakeCase;

  /// Title Case
  String get titleCase => ReCase(this).titleCase;

  /// UPPER CASE
  String get upperCase => toUpperCase();
}
