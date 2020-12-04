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
  String render(dynamic values) {
    final template = Template(this, lenient: true);

    /// camelCase
    final camelCase = (LambdaContext ctx) => ctx.renderString().camelCase;

    /// CONSTANT_CASE
    final constantCase = (LambdaContext ctx) => ctx.renderString().constantCase;

    /// dot.case
    final dotCase = (LambdaContext ctx) => ctx.renderString().dotCase;

    /// Header-Case
    final headerCase = (LambdaContext ctx) => ctx.renderString().headerCase;

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

    return template.renderString(<String, dynamic>{
      'camelCase': camelCase,
      'constantCase': constantCase,
      'dotCase': dotCase,
      'headerCase': headerCase,
      'pascalCase': pascalCase,
      'paramCase': paramCase,
      'pathCase': pathCase,
      'sentenceCase': sentenceCase,
      'snakeCase': snakeCase,
      'titleCase': titleCase,
      ...values,
    });
  }
}
