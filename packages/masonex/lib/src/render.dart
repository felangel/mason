import 'dart:async';
import 'dart:convert';

import 'package:masonex/masonex.dart';
import 'package:mustachex/mustachex.dart';

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
  'lowerCase': (ctx) => ctx.renderString().lowerCase,

  /// {{ mustache case }}
  'mustacheCase': (ctx) => ctx.renderString().mustacheCase,

  /// PascalCase
  'pascalCase': (ctx) => ctx.renderString().pascalCase,

  /// Pascal.Dot.Case
  'pascalDotCase': (ctx) => ctx.renderString().pascalDotCase,

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
  'upperCase': (ctx) => ctx.renderString().upperCase,
};

/// [Map] of all the built-in variables.
const _builtInVars = <String, dynamic>{
  '__LEFT_CURLY_BRACKET__': '{',
  '__RIGHT_CURLY_BRACKET__': '}',
};

/// {@template render_template}
/// Given a `String` with mustache templates, and a [Map] of String key /
/// value pairs, substitute all instances of `{{key}}` for `value`.
///
/// ```text
/// Hello {{name}}!
/// ```
///
/// and
///
/// ```text
/// {'name': 'Bob'}
/// ```
///
/// becomes:
///
/// ```text
/// Hello Bob!
/// ```
/// {@endtemplate}
extension RenderTemplate on String {
  /// {@macro render_template}
  Future<String> render(
    Map<String, dynamic> vars, {
    Map<String, List<int>>? partials = const {},
    FutureOr<String> Function(String variable)? onMissingVariable,
  }) async {
    final processor = MustachexProcessor(
      initialVariables: <String, dynamic>{
        ...vars,
        ..._builtInLambdas,
        ..._builtInVars,
      },
      missingVarFulfiller: onMissingVariable != null
          ? (exception) async => await onMissingVariable(exception.request)
          : null,
      partialsResolver: (exception) {
        final name = exception.partialName;
        if (name == null) return null;
        final content = partials?['{{~ $name }}'];
        if (content == null) return null;
        final decoded = utf8.decode(content);
        return _sanitizeInput(decoded.transpiled());
      },
    );

    return _sanitizeOutput(
      await processor.process(_sanitizeInput(transpiled())),
    );
  }
}

extension on String {
  String transpiled() {
    final builtInLambdaNamesEscaped =
        _builtInLambdas.keys.map(RegExp.escape).join('|');
    final lambdaPattern = RegExp(
      '{?{{ *([^{}]*?)(?:\\.($builtInLambdaNamesEscaped)\\(\\) *| *\\| *([a-zA-Z0-9_]+) *)}}}?',
    );

    var currentIteration = this;

    while (lambdaPattern.hasMatch(currentIteration)) {
      currentIteration =
          currentIteration.replaceAllMapped(lambdaPattern, (match) {
        final expression = match.group(0)!;
        final variable = match.group(1)!.trim();
        final lambda = match.group(2) ?? match.group(3);

        if (lambda == null) return expression;

        final startsWithTriple = expression.startsWith('{{{');
        final endsWithTriple = expression.endsWith('}}}');
        final isTriple = startsWithTriple && endsWithTriple;

        final output = isTriple ? '{{{$variable}}}' : '{{$variable}}';

        if (startsWithTriple && !isTriple) {
          return '{{__LEFT_CURLY_BRACKET__}}{{#$lambda}}$output{{/$lambda}}';
        }

        if (endsWithTriple && !isTriple) {
          return '{{#$lambda}}$output{{/$lambda}}{{__RIGHT_CURLY_BRACKET__}}';
        }

        return '{{#$lambda}}$output{{/$lambda}}';
      });
    }

    return currentIteration;
  }
}

/// {@template resolve_partial}
/// A resolver function which given a partial name.
/// attempts to return a new [Template].
/// {@endtemplate}
extension ResolvePartial on Map<String, List<int>> {
  /// {@macro resolve_partial}
  Template? resolve(String name) {
    final content = this['{{~ $name }}'];
    if (content == null) return null;
    final decoded = utf8.decode(content);
    final sanitized = _sanitizeInput(decoded.transpiled());
    return Template(sanitized, name: name, lenient: true);
  }
}
