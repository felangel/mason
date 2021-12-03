import 'dart:convert';

import 'package:mustache_template/mustache.dart';
import 'package:recase/recase.dart';

/// {@template templateX}
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
extension TemplateX on String {
  /// {@macro templateX}
  String render(dynamic values, [PartialResolver? partialResolver]) {
    final template = Template(
      this,
      lenient: true,
      partialResolver: partialResolver,
    );

    /// camelCase
    final camelCase = (LambdaContext ctx) => ctx.renderString().camelCase;

    /// CONSTANT_CASE
    final constantCase = (LambdaContext ctx) => ctx.renderString().constantCase;

    /// dot.case
    final dotCase = (LambdaContext ctx) => ctx.renderString().dotCase;

    /// Header-Case
    final headerCase = (LambdaContext ctx) => ctx.renderString().headerCase;

    /// lower case
    final lowerCase = (LambdaContext ctx) => ctx.renderString().toLowerCase();

    /// PascalCase
    final pascalCase = (LambdaContext ctx) => ctx.renderString().pascalCase;

    /// param-case
    final paramCase = (LambdaContext ctx) => ctx.renderString().paramCase;

    /// path/case
    final pathCase = (LambdaContext ctx) => ctx.renderString().pathCase;

    /// Sentence case
    final sentenceCase = (LambdaContext ctx) => ctx.renderString().sentenceCase;

    /// snake_case
    final snakeCase = (LambdaContext ctx) => ctx.renderString().snakeCase;

    /// Title Case
    final titleCase = (LambdaContext ctx) => ctx.renderString().titleCase;

    /// UPPER CASE
    final upperCase = (LambdaContext ctx) => ctx.renderString().toUpperCase();

    return template.renderString(<String, dynamic>{
      'camelCase': camelCase,
      'constantCase': constantCase,
      'dotCase': dotCase,
      'headerCase': headerCase,
      'lowerCase': lowerCase,
      'pascalCase': pascalCase,
      'paramCase': paramCase,
      'pathCase': pathCase,
      'sentenceCase': sentenceCase,
      'snakeCase': snakeCase,
      'titleCase': titleCase,
      'upperCase': upperCase,
      ...values,
    });
  }
}

/// A resolver function which given a partial [name] and
/// a map of registered partials, attempts to return a new [Template].
Template? partialResolver(
  String name,
  Map<String, List<int>> partials, [
  String Function(String)? sanitize,
]) {
  final content = partials['{{~ $name }}'];
  if (content == null) return null;
  final decoded = utf8.decode(content);
  final sanitized = sanitize?.call(decoded) ?? decoded;
  return Template(sanitized, name: name, lenient: true);
}
