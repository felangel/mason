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
    Map<String, dynamic> vars, [
    Map<String, List<int>>? partials = const {},
  ]) {
    final template = Template(
      _sanitizeInput(transpiled(vars)),
      lenient: true,
      partialResolver: partials?.resolve,
    );

    return _sanitizeOutput(
      template.renderString(<String, dynamic>{..._builtInLambdas, ...vars}),
    );
  }
}

extension on String {
  String transpiled(Map<String, dynamic> vars) {
    final delimeterRegExp = RegExp('({?{{.*?}}}?)');
    final lambdasRegExp = RegExp(
      r'''((.*).(camelCase|constantCase|dotCase|headerCase|lowerCase|pascalCase|paramCase|pathCase|sentenceCase|snakeCase|titleCase|upperCase)\(\))''',
    );

    final containsLambdas = lambdasRegExp.hasMatch(this);
    if (!containsLambdas) return this;

    return replaceAllMapped(delimeterRegExp, (match) {
      final group = match.group(1);
      if (group == null) return this;

      final isTriple = group.startsWith('{{{') && group.endsWith('}}}');
      final groupContents = isTriple
          ? group.substring(3, group.length - 3)
          : group.substring(2, group.length - 2);

      return groupContents.replaceAllMapped(lambdasRegExp, (lambdaMatch) {
        final lambdaGroup = lambdaMatch.group(1);
        if (lambdaGroup == null) return groupContents;

        final segments = lambdaGroup.split('.');
        if (segments.length == 1) return groupContents;

        final variable = segments.first;
        if (!vars.containsKey(variable)) return groupContents;

        var output = isTriple ? '{{{$variable}}}' : '{{$variable}}';
        for (var i = 1; i < segments.length; i++) {
          final lambda = segments[i].replaceFirst('()', '');
          output = '{{#$lambda}}$output{{/$lambda}}';
        }

        return output;
      });
    });
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
