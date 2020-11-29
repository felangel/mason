import 'dart:convert';
import 'dart:io';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/src/generator.dart';
import 'package:mason/src/mason_yaml.dart';

import '../command.dart';

/// {@template make_command}
/// `mason make` command which generates code based on a brick template.
/// {@endtemplate}
class MakeCommand extends MasonCommand {
  /// {@macro make_command}
  MakeCommand() {
    argParser.addOption(
      'json',
      abbr: 'j',
      help: 'Path to json file containing variables',
    );
  }

  @override
  final String description = 'Generate code using an existing brick template.';

  @override
  final String name = 'make';

  @override
  Future<int> run() async {
    if (masonYamlFile == null) {
      logger.err(
        'Cannot find ${MasonYaml.file}.\nDid you forget to run mason init?',
      );
      return ExitCode.ioError.code;
    }

    final args = argResults.rest;
    final brickName = args.first;
    final brick = masonYaml.bricks[brickName];
    final target = DirectoryGeneratorTarget(cwd, logger);

    if (brick == null) {
      logger.err(
        'Missing brick: $brickName.\n'
        'Add the $brickName brick to the ${MasonYaml.file} '
        'and try again.',
      );
      return ExitCode.usage.code;
    }

    final fetchDone = logger.progress('Getting brick $brickName');
    Function generateDone;
    try {
      final generator = await MasonGenerator.fromBrick(
        brick,
        workingDirectory: entryPoint.path,
      );
      fetchDone('Got brick $brickName');

      final vars = <String, dynamic>{};
      try {
        vars.addAll(await _decodeFile(argResults['json'] as String));
      } on FormatException catch (error) {
        logger.err('${error}in ${argResults['json']}');
        return ExitCode.usage.code;
      } on Exception catch (error) {
        logger.err('$error');
        return ExitCode.usage.code;
      }

      for (final variable in generator.vars ?? const <String>[]) {
        if (vars.containsKey(variable)) continue;
        final index = args.indexOf('--$variable');
        if (index != -1) {
          vars.addAll(
            <String, dynamic>{variable: _maybeDecode(args[index + 1])},
          );
        } else {
          vars.addAll(
            <String, dynamic>{
              variable: _maybeDecode(logger.prompt('$variable: '))
            },
          );
        }
      }

      generateDone = logger.progress('Making ${generator.id}');
      await generator.generate(target, vars: vars);
      generateDone('Made brick $brickName');
      logger
        ..info(
          '${lightGreen.wrap('✓')} '
          'Generated ${generator.files.length} file(s):',
        )
        ..flush(logger.success);
      return ExitCode.success.code;
    } on Exception catch (e) {
      fetchDone();
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
