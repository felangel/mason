import 'dart:convert';

import 'package:mustache_template/mustache_template.dart';
import 'package:recase/recase.dart';

final _newlineInRegExp = RegExp(r'(\\\r\n|\\\r|\\\n)');
final _newlineOutRegExp = RegExp(r'(\r\n|\r|\n)');
final _unicodeInRegExp = RegExp(r'\\[^\x00-\x7F]');
final _unicodeOutRegExp = RegExp(r'[^\x00-\x7F]');

String _sanitizeInput(String input) {
  return input.replaceAllMapped(
    RegExp('${_newlineOutRegExp.pattern}|${_unicodeOutRegExp.pattern}'),
    (match) => match.group(0) != null ? '\\${match.group(0)}' : match.input,
  );
}

String _sanitizeOutput(String output) {
  return output.replaceAllMapped(
    RegExp('${_newlineInRegExp.pattern}|${_unicodeInRegExp.pattern}'),
    (match) => match.group(0)?.substring(1) ?? match.input,
  );
}

/// [Map] of all the built-in lambda functions.
final _builtInLambdas = <String, LambdaFunction>{
  /// camelCase
  'camelCase': (ctx) => ctx.renderString().camelCase,

  /// CONSTANT_CASE
  'constantCase': (ctx) => ctx.renderString().constantCase,

  /// dot.case
  'dotCase': (ctx) => ctx.renderString().dotCase,

  /// Header-Case
  'headerCase': (ctx) => ctx.renderString().headerCase,

  /// lower case
  'lowerCase': (ctx) => ctx.renderString().toLowerCase(),

  /// PascalCase
  'pascalCase': (ctx) => ctx.renderString().pascalCase,

  /// param-case
  'paramCase': (ctx) => ctx.renderString().paramCase,

  /// path/case
  'pathCase': (ctx) => ctx.renderString().pathCase,

  /// Sentence case
  'sentenceCase': (ctx) => ctx.renderString().sentenceCase,

  /// snake_case
  'snakeCase': (ctx) => ctx.renderString().snakeCase,

  /// Title Case
  'titleCase': (ctx) => ctx.renderString().titleCase,

  /// UPPER CASE
  'upperCase': (ctx) => ctx.renderString().toUpperCase(),
};

/// {@template render_template}
/// Given a `String` with mustache templates, and a [Map] of String key /
/// value pairs, substitute all instances of `{{key}}` for `value`.
///
/// ```
/// Hello {{name}}!
/// ```
///
/// and
///
/// ```
/// {'name': 'Bob'}
/// ```
///
/// becomes:
///
/// ```
/// Hello Bob!
/// ```
/// {@endtemplate}
extension RenderTemplate on String {
  /// {@macro render_template}
  String render(
    Map<String, dynamic> vars,
    Map<String, String> aliases, [
    Map<String, List<int>>? partials = const {},
  ]) {
    var content = this;
    for (final alias in aliases.entries) {
      content = content.replaceAll(alias.key, alias.value);
    }

    final template = Template(
      _sanitizeInput(content),
      lenient: true,
      partialResolver: partials?.resolve,
    );

    return _sanitizeOutput(
      template.renderString(<String, dynamic>{..._builtInLambdas, ...vars}),
    );
  }
}

/// {template resolve_partial}
/// A resolver function which given a partial name.
/// attempts to return a new [Template].
/// {@endtemplate}
extension ResolvePartial on Map<String, List<int>> {
  /// {@macro resolve_partial}
  Template? resolve(final String name) {
    final content = this['{{~ $name }}'];
    if (content == null) return null;
    final decoded = utf8.decode(content);
    final sanitized = _sanitizeInput(decoded);
    return Template(sanitized, name: name, lenient: true);
  }
}
