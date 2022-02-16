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
final _builtInLambdas = <String, String Function(String)>{
  /// camelCase
  'camelCase': (ctx) => ctx.camelCase,

  /// CONSTANT_CASE
  'constantCase': (ctx) => ctx.constantCase,

  /// dot.case
  'dotCase': (ctx) => ctx.dotCase,

  /// Header-Case
  'headerCase': (ctx) => ctx.headerCase,

  /// lower case
  'lowerCase': (ctx) => ctx.toLowerCase(),

  /// PascalCase
  'pascalCase': (ctx) => ctx.pascalCase,

  /// param-case
  'paramCase': (ctx) => ctx.paramCase,

  /// path/case
  'pathCase': (ctx) => ctx.pathCase,

  /// Sentence case
  'sentenceCase': (ctx) => ctx.sentenceCase,

  /// snake_case
  'snakeCase': (ctx) => ctx.snakeCase,

  /// Title Case
  'titleCase': (ctx) => ctx.titleCase,

  /// UPPER CASE
  'upperCase': (ctx) => ctx.toUpperCase(),
};

/// [Map] of all the built-in lambda functions transformed for mustache
final _builtInMustacheLambdas = <String, LambdaFunction>{
  for (final entry in _builtInLambdas.entries)
    entry.key: (ctx) => entry.value(ctx.renderString()),
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
    Map<String, dynamic> vars, [
    Map<String, List<int>>? partials = const {},
  ]) {
    final thisWithShortcutsRendered = renderShortcuts(vars);

    final template = Template(
      _sanitizeInput(thisWithShortcutsRendered),
      lenient: true,
      partialResolver: partials?.resolve,
    );

    return _sanitizeOutput(
      template
          .renderString(<String, dynamic>{..._builtInMustacheLambdas, ...vars}),
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

extension on String {
  /// Renders shortcuts with the syntax `{{variable_name|lambda_name}}`
  String renderShortcuts(Map<String, dynamic> vars) {
    final lambdas = _builtInLambdas;

    return replaceAllMapped(
      RegExp(r'\{\{.+\|.+\}\}'),
      (match) {
        final matchString = match.group(0) ?? '';

        final keywords = matchString.removeAll('{{').removeAll('}}');
        final variableAndLambda = keywords.split('|');
        final variableName = variableAndLambda.first;
        final lambdaNames = variableAndLambda.sublist(1);

        final hasMatchingVar = vars.containsKey(variableName);

        /// Guard no matching variable
        if (!hasMatchingVar) return matchString;
        final variable = vars[variableName]! as String;

        var transformedVariable = variable;

        for (final lambdaName in lambdaNames) {
          final hasMatchingLambda = lambdas.containsKey(lambdaName);

          /// Guard no matching lambda
          if (!hasMatchingLambda) return matchString;
          final lambda = lambdas[lambdaName]!;

          transformedVariable = lambda(transformedVariable);
        }

        return transformedVariable;
      },
    );
  }

  String removeAll(Pattern pattern) => replaceAll(pattern, '');
}
