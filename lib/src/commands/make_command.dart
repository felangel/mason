import 'dart:convert';
import 'dart:io';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' as io;
import 'package:mason/src/generator.dart';
import 'package:mason/src/mason_yaml.dart';
import 'package:path/path.dart' as path;
import 'package:args/command_runner.dart';

import '../logger.dart';

/// {@template make_command}
/// `mason make` command which generates code based on a brick template.
/// {@endtemplate}
class MakeCommand extends Command<dynamic> {
  /// {@macro make_command}
  MakeCommand(this._logger) {
    argParser.addOption(
      'json',
      abbr: 'j',
      help: 'Path to json file containing variables',
    );
  }

  final Logger _logger;

  @override
  final String description = 'Generate code using an existing brick template.';

  @override
  final String name = 'make';

  Directory _cwd;

  /// Return the current working directory.
  Directory get cwd => _cwd ?? Directory.current;

  /// An override for the directory to generate into; public for testing.
  set cwd(Directory value) => _cwd = value;

  @override
  void run() async {
    final args = argResults.rest;
    final brickName = args.first;
    final masonConfigFile = MasonYaml.findNearest(cwd);
    if (masonConfigFile == null) {
      _logger.err(
        '''Missing ${MasonYaml.file} at ${path.join(cwd.path, MasonYaml.file)}.\nRun mason init, add the $brickName brick, and try again.''',
      );
      return;
    }

    final masonConfigContent = masonConfigFile.existsSync()
        ? masonConfigFile.readAsStringSync()
        : null;
    if (masonConfigContent == null || masonConfigContent.isEmpty) {
      _logger.err(
        '''Malformed ${MasonYaml.file} at ${path.join(cwd.path, 'mason.yaml')}''',
      );
      return;
    }

    final masonConfig = checkedYamlDecode(
      masonConfigContent,
      (m) => MasonYaml.fromJson(m),
    );
    final brick = masonConfig.bricks[brickName];
    final target = DirectoryGeneratorTarget(cwd, _logger);

    if (brick == null) {
      _logger.err(
        'Missing brick: $brickName.\n'
        'Add the $brickName brick to the ${MasonYaml.file} '
        'and try again.',
      );
      exitCode = io.ExitCode.usage.code;
      return;
    }

    final fetchDone = _logger.progress('Getting brick $brickName');
    Function generateDone;
    try {
      final generator = await MasonGenerator.fromBrick(
        brick,
        workingDirectory: masonConfigFile.parent.path,
      );
      fetchDone('Got brick $brickName');

      final vars = <String, dynamic>{};
      try {
        vars.addAll(await _decodeFile(argResults['json'] as String));
      } on FormatException catch (error) {
        _logger.err('${error}in ${argResults['json']}');
        exitCode = io.ExitCode.usage.code;
        return;
      } on Exception catch (error) {
        _logger.err('$error');
        exitCode = io.ExitCode.usage.code;
        return;
      }

      for (final variable in generator.vars) {
        if (vars.containsKey(variable)) continue;
        final index = args.indexOf('--$variable');
        if (index != -1) {
          vars.addAll(
            <String, dynamic>{variable: _maybeDecode(args[index + 1])},
          );
        } else {
          vars.addAll(
            <String, dynamic>{
              variable: _maybeDecode(_logger.prompt('$variable: '))
            },
          );
        }
      }

      generateDone = _logger.progress('Making ${generator.id}');
      await generator.generate(target, vars: vars);
      generateDone('Made brick $brickName');
      _logger
        ..info(
          '''${lightGreen.wrap('✓')} Generated ${generator.files.length} file(s):''',
        )
        ..flush(_logger.success);
      exit(io.ExitCode.success.code);
    } on Exception catch (e) {
      fetchDone();
      generateDone?.call();
      _logger.err(e.toString());
      exit(io.ExitCode.cantCreate.code);
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
