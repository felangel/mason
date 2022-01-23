part of 'generator.dart';

/// A reference to core mason APIs to be used within hooks.
///
/// Each hook is defined as a `run` method which accepts a
/// [HookContext] instance.
///
/// [HookContext] exposes APIs to:
/// * read/write template vars
/// * access a [Logger] instance
///
/// ```dart
/// // pre_gen.dart
/// import 'package:mason/mason.dart';
///
/// void run(HookContext context) {
///   // Read/Write vars
///   context.vars = {...context.vars, 'custom_var': 'foo'};
///
///   // Use the logger
///   context.logger.info('hello from pre_gen.dart');
/// }
/// ```
abstract class HookContext {
  /// Getter that returns the current map of variables.
  Map<String, dynamic> get vars;

  /// Setter that enables updating the current map of variables.
  set vars(Map<String, dynamic> value);

  /// Getter that returns a [Logger] instance.
  Logger get logger;
}

Uri _getHookUri(List<int> content) {
  final encoded = utf8.decode(content);
  final code = _generatedHookCode(encoded);
  return Uri.dataFromString(code, mimeType: 'application/dart');
}

String _generatedHookCode(String content) => '''
// GENERATED CODE - DO NOT MODIFY BY HAND
import 'dart:convert';
import 'dart:isolate';

$content

void main(List<String> args, SendPort port) {
  run(_HookContext._(port, vars: json.decode(args.first)));
}

class _HookContext implements HookContext {
  _HookContext._(
    this._port, {
    Map<String, dynamic>? vars,
  }) : _vars = vars ?? <String, dynamic>{};

  final SendPort _port;
  Map<String, dynamic> _vars;

  @override
  Map<String, dynamic> get vars => _vars;

  @override
  final logger = Logger();

  @override
  set vars(Map<String, dynamic> value) {
    _vars = value;
    _port.send(_vars);
  }
}
''';
