import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:mason/src/generator.dart';
import 'package:path/path.dart' as p;

import '../logger.dart';
import '../mason_configuration.dart';

/// {@template init_command}
/// `mason init` command which initializes a new `mason.yaml`.
/// {@endtemplate}
class InitCommand extends Command<dynamic> {
  /// {@macro init_command}
  InitCommand(this._logger);

  final Logger _logger;

  @override
  final String description = 'Initialize a new ${MasonConfiguration.yaml}.';

  @override
  final String name = 'init';

  Directory _cwd;

  /// Return the current working directory.
  Directory get cwd => _cwd ?? Directory.current;

  /// An override for the directory to generate into; public for testing.
  set cwd(Directory value) => _cwd = value;

  @override
  void run() async {
    final masonYaml = File(p.join(cwd.path, MasonConfiguration.yaml));
    if (masonYaml.existsSync()) {
      _logger.err('Existing ${MasonConfiguration.yaml} at ${masonYaml.path}');
      return;
    }
    final fetchDone = _logger.progress('Initializing');
    final target = DirectoryGeneratorTarget(cwd, _logger);
    final generator = _MasonYamlGenerator();
    await generator.generate(target);
    fetchDone('Initialized');
    _logger
      ..info(
        '${lightGreen.wrap('✓')} Generated ${generator.files.length} file(s):',
      )
      ..flush(_logger.success);
  }
}

class _MasonYamlGenerator extends MasonGenerator {
  _MasonYamlGenerator()
      : super(
          '__mason_init__',
          'Initialize a new ${MasonConfiguration.yaml}',
          files: [TemplateFile(MasonConfiguration.yaml, 'bricks:\n')],
        );
}
