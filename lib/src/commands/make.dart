import 'dart:convert';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/generator.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

import '../brick_yaml.dart';
import '../command.dart';
import '../io.dart';

/// {@template make_command}
/// `mason make` command which generates code based on a brick template.
/// {@endtemplate}
class MakeCommand extends MasonCommand {
  /// {@macro make_command}
  MakeCommand({Logger? logger}) : super(logger: logger) {
    argParser.addOptions();
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
    argParser.addOptions();
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
    final outputDir = p.canonicalize(
      p.join(cwd.path, results['output-dir'] as String),
    );
    final configPath = results['config-path'] as String?;
    final fileConflictResolution =
        (results['on-conflict'] as String).toFileConflictResolution();
    final target = DirectoryGeneratorTarget(
      Directory(outputDir),
      logger,
      fileConflictResolution,
    );

    Function? generateDone;

    try {
      final generator = await MasonGenerator.fromBrickYaml(_brick);
      final vars = <String, dynamic>{};

      try {
        vars.addAll(await _decodeFile(configPath));
      } on FormatException catch (error) {
        logger.err('${error}in $configPath');
        return ExitCode.usage.code;
      } catch (error) {
        logger.err('$error');
        return ExitCode.usage.code;
      }

      for (final variable in _brick.vars) {
        if (vars.containsKey(variable)) continue;
        final arg = results[variable] as String?;
        if (arg != null) {
          vars.addAll(<String, dynamic>{variable: _maybeDecode(arg)});
        } else {
          vars.addAll(<String, dynamic>{
            variable: _maybeDecode(logger.prompt('$variable: '))
          });
        }
      }

      final preGenScript = generator.hooks.preGen;
      if (preGenScript != null) {
        final exitCode = await preGenScript.run(vars, logger, outputDir);
        if (exitCode != ExitCode.success.code) return exitCode;
      }

      generateDone = logger.progress('Making ${generator.id}');
      final fileCount = await generator.generate(target, vars: vars);
      generateDone('Made brick ${_brick.name}');
      logger.logFiles(fileCount);

      final postGenScript = generator.hooks.postGen;
      if (postGenScript != null) {
        final exitCode = await postGenScript.run(vars, logger, outputDir);
        if (exitCode != ExitCode.success.code) return exitCode;
      }

      return ExitCode.success.code;
    } catch (error) {
      generateDone?.call();
      logger.err('$error');
      return ExitCode.cantCreate.code;
    }
  }

  Future<Map<String, dynamic>> _decodeFile(String? path) async {
    if (path == null) return <String, dynamic>{};
    final content = await File(path).readAsString();
    return json.decode(content) as Map<String, dynamic>;
  }

  dynamic _maybeDecode(String value) {
    try {
      return json.decode(value);
    } catch (_) {
      return value;
    }
  }
}

extension on ArgParser {
  void addOptions() {
    addOption(
      'config-path',
      abbr: 'c',
      help: 'Path to config json file containing variables.',
    );
    addOption(
      'output-dir',
      abbr: 'o',
      help: 'Directory where to output the generated code.',
      defaultsTo: '.',
    );
    addOption(
      'on-conflict',
      allowed: ['prompt', 'overwrite', 'append', 'skip'],
      defaultsTo: 'prompt',
      allowedHelp: {
        'prompt': 'Always prompt the user for each file conflict.',
        'overwrite': 'Always overwrite conflicting files.',
        'append': 'Always append conflicting files.',
        'skip': 'Always skip conflicting files.',
      },
      help: 'File conflict resolution strategy.',
    );
  }
}

extension on String {
  FileConflictResolution toFileConflictResolution() {
    switch (this) {
      case 'skip':
        return FileConflictResolution.skip;
      case 'overwrite':
        return FileConflictResolution.overwrite;
      case 'append':
        return FileConflictResolution.append;
      default:
        return FileConflictResolution.prompt;
    }
  }
}

extension on Logger {
  void logFiles(int fileCount) {
    if (fileCount == 0) {
      info(
        '${lightGreen.wrap('✓')} '
        'Generated $fileCount files',
      );
    } else if (fileCount == 1) {
      this
        ..info(
          '${lightGreen.wrap('✓')} '
          'Generated $fileCount file:',
        )
        ..flush(detail);
    } else {
      this
        ..info(
          '${lightGreen.wrap('✓')} '
          'Generated $fileCount file(s):',
        )
        ..flush(detail);
    }
  }
}

extension on ScriptFile {
  Future<int> run(
    Map<String, dynamic> vars,
    Logger logger,
    String workingDirectory,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync();
    final script = File(p.join(tempDir.path, p.basename(path)))
      ..writeAsBytesSync(runSubstitution(vars).content);
    final isDart = p.extension(path) == '.dart';
    final result = await Process.run(
      isDart ? 'dart' : 'bash',
      [script.path],
      workingDirectory: workingDirectory,
    );

    final stdout = result.stdout as String?;
    if (stdout != null && stdout.isNotEmpty) logger.info(stdout.trim());

    final stderr = result.stderr as String?;
    if (stderr != null && stderr.isNotEmpty) logger.err(stderr.trim());

    return result.exitCode;
  }
}
