import 'dart:convert';
import 'dart:io';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/src/generator.dart';

import '../brick_yaml.dart';
import '../command.dart';

/// {@template make_command}
/// `mason make` command which generates code based on a brick template.
/// {@endtemplate}
class MakeCommand extends MasonCommand {
  /// {@macro make_command}
  MakeCommand() {
    try {
      for (final brick in bricks) {
        addSubcommand(_MakeCommand(brick));
      }
    } catch (e) {
      _exception = e;
    }
  }

  dynamic _exception;

  @override
  final String description = 'Generate code using an existing brick template.';

  @override
  final String name = 'make';

  @override
  Future<int> run() async {
    if (_exception != null) throw _exception;
    return ExitCode.success.code;
  }
}

class _MakeCommand extends MasonCommand {
  _MakeCommand(this._brick) {
    argParser.addOption(
      'json',
      abbr: 'j',
      help: 'Path to json file containing variables',
    );
    for (final arg in _brick.vars) {
      argParser.addOption(arg);
    }
  }

  final BrickYaml _brick;

  @override
  String get description => _brick.description;

  @override
  String get name => _brick.name;

  @override
  Future<int> run() async {
    final target = DirectoryGeneratorTarget(cwd, logger);

    Function generateDone;
    try {
      final generator = await MasonGenerator.fromBrickYaml(_brick);
      final vars = <String, dynamic>{};
      generateDone = logger.progress('Making ${generator.id}');

      try {
        vars.addAll(await _decodeFile(argResults['json'] as String));
      } on FormatException catch (error) {
        generateDone();
        logger.err('${error}in ${argResults['json']}');
        return ExitCode.usage.code;
      } on Exception catch (error) {
        generateDone();
        logger.err('$error');
        return ExitCode.usage.code;
      }

      for (final variable in _brick.vars ?? const <String>[]) {
        if (vars.containsKey(variable)) continue;
        final arg = argResults[variable] as String;
        if (arg != null) {
          vars.addAll(
            <String, dynamic>{variable: _maybeDecode(arg)},
          );
        } else {
          vars.addAll(
            <String, dynamic>{
              variable: _maybeDecode(logger.prompt('$variable: '))
            },
          );
        }
      }

      await generator.generate(target, vars: vars);
      generateDone('Made brick ${_brick.name}');
      logger
        ..info(
          '${lightGreen.wrap('✓')} '
          'Generated ${generator.files.length} file(s):',
        )
        ..flush(logger.success);
      return ExitCode.success.code;
    } on Exception catch (e) {
      generateDone?.call();
      logger.err(e.toString());
      return ExitCode.cantCreate.code;
    }
  }

  Future<Map<String, dynamic>> _decodeFile(String path) async {
    if (path == null) return <String, dynamic>{};
    final jsonVarsContent = await File(path).readAsString();
    return json.decode(jsonVarsContent) as Map<String, dynamic>;
  }

  Object _maybeDecode(String value) {
    try {
      return json.decode(value);
    } catch (_) {
      return value;
    }
  }
}
