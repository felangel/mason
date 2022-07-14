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

  /// {{ mustache case }}
  'mustacheCase': (ctx) => '{{ ${ctx.renderString()} }}',

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
    Map<String, dynamic> vars, [
    Map<String, List<int>>? partials = const {},
  ]) {
    final template = Template(
      _sanitizeInput(transpiled(vars)),
      lenient: true,
      partialResolver: (name) => partials?.resolve(name, vars: vars),
    );

    return _sanitizeOutput(
      template.renderString(<String, dynamic>{..._builtInLambdas, ...vars}),
    );
  }
}

extension on String {
  String transpiled(Map<String, dynamic> vars) {
    final builtInLambdaNamesEscaped =
        _builtInLambdas.keys.map(RegExp.escape).join('|');
    final lambdaPattern =
        RegExp('{?{{([^}]*)\\.($builtInLambdaNamesEscaped)\\(\\)}}}?');

    var currentIteration = this;

    // Continue substituting until no match is found to account for chained
    // lambdas
    while (lambdaPattern.hasMatch(currentIteration)) {
      currentIteration =
          currentIteration.replaceAllMapped(lambdaPattern, (match) {
        final variable = match.group(1)!;
        final lambda = match.group(2)!;

        final isTriple = match.group(0)!.startsWith('{{{');

        final output = isTriple ? '{{{$variable}}}' : '{{$variable}}';

        return '{{#$lambda}}$output{{/$lambda}}';
      });
    }

    return currentIteration;
  }
}

/// {template resolve_partial}
/// A resolver function which given a partial name.
/// attempts to return a new [Template].
/// {@endtemplate}
extension ResolvePartial on Map<String, List<int>> {
  /// {@macro resolve_partial}
  Template? resolve(
    final String name, {
    Map<String, dynamic> vars = const <String, dynamic>{},
  }) {
    final content = this['{{~ $name }}'];
    if (content == null) return null;
    final decoded = utf8.decode(content);
    final sanitized = _sanitizeInput(decoded.transpiled(vars));
    return Template(sanitized, name: name, lenient: true);
  }
}
