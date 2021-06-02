import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/generator.dart';

import '../brick_yaml.dart';
import '../command.dart';

/// {@template make_command}
/// `mason make` command which generates code based on a brick template.
/// {@endtemplate}
class MakeCommand extends MasonCommand {
  /// {@macro make_command}
  MakeCommand({Logger? logger}) : super(logger: logger) {
    try {
      for (final brick in bricks) {
        addSubcommand(_MakeCommand(brick, logger: logger));
      }
    } catch (e) {
      _exception = e;
    }
  }

  Object? _exception;

  @override
  final String description = 'Generate code using an existing brick template.';

  @override
  final String name = 'make';

  @override
  Future<int> run() async {
    // ignore: only_throw_errors
    if (_exception != null) throw _exception!;
    final subcommand = results.rest.isNotEmpty ? results.rest.first : '';
    throw UsageException(
      '''Could not find a subcommand named "$subcommand" for "mason make".''',
      usage,
    );
  }
}

class _MakeCommand extends MasonCommand {
  _MakeCommand(this._brick, {Logger? logger}) : super(logger: logger) {
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

    Function? generateDone;
    try {
      final generator = await MasonGenerator.fromBrickYaml(_brick);
      final vars = <String, dynamic>{};
      generateDone = logger.progress('Making ${generator.id}');

      try {
        vars.addAll(await _decodeFile(results['json'] as String?));
      } on FormatException catch (error) {
        generateDone();
        logger.err('${error}in ${results['json']}');
        return ExitCode.usage.code;
      } on Exception catch (error) {
        generateDone();
        logger.err('$error');
        return ExitCode.usage.code;
      }

      for (final variable in _brick.vars) {
        if (vars.containsKey(variable)) continue;
        final arg = results[variable] as String?;
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
      final fileCount = await generator.generate(target, vars: vars);
      generateDone('Made brick ${_brick.name}');
      logger
        ..info(
          '${lightGreen.wrap('✓')} '
          'Generated $fileCount file(s):',
        )
        ..flush(logger.success);
      return ExitCode.success.code;
    } on Exception catch (error) {
      generateDone?.call();
      logger.err('$error');
      return ExitCode.cantCreate.code;
    }
  }

  Future<Map<String, dynamic>> _decodeFile(String? path) async {
    if (path == null) return <String, dynamic>{};
    final jsonVarsContent = await File(path).readAsString();
    return json.decode(jsonVarsContent) as Map<String, dynamic>;
  }

  dynamic _maybeDecode(String value) {
    try {
      return json.decode(value);
    } catch (_) {
      return value;
    }
  }
}
