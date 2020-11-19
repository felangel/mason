import 'dart:io' as io;
import 'package:io/io.dart';
import 'package:mason/src/generator.dart';
import 'package:path/path.dart' as path;
import 'package:args/command_runner.dart';

import '../logger.dart';

/// {@template build_command}
/// `mason build` command which generates code based on a pre-existing template.
/// {@endtemplate}
class BuildCommand extends Command<dynamic> {
  /// {@macro build_command}
  BuildCommand(this._logger) {
    argParser.addOption('template', abbr: 't', help: 'template yaml path');
  }

  final Logger _logger;

  @override
  final String description = 'Generate code using an existing template.';

  @override
  final String name = 'build';

  io.Directory _cwd;

  /// Return the current working directory.
  io.Directory get cwd => _cwd ?? io.Directory.current;

  /// An override for the directory to generate into; public for testing.
  set cwd(io.Directory value) => _cwd = value;

  @override
  void run() async {
    final template = argResults['template'] as String;
    final args = argResults.rest;
    final dir = cwd;
    final target = _DirectoryGeneratorTarget(_logger, dir);

    if (template == null || template.isEmpty) {
      _logger
        ..err('Specify a template')
        ..info('')
        ..info(usage);
      io.exitCode = ExitCode.usage.code;
      return;
    }

    final stop = _logger.progress('building');
    try {
      final generator = await MasonGenerator.fromYaml(template);
      final vars = <String, String>{};

      for (final variable in generator.vars) {
        final index = args.indexOf('--$variable');
        if (index != -1) {
          vars.addAll({variable: args[index + 1]});
        }
      }

      await generator.generate(target, vars: vars);
      stop();
      _logger.success('built [${generator.id}] in ${target.dir.path}');
    } on Exception catch (e) {
      stop();
      _logger.err(e.toString());
    }
  }
}

class _DirectoryGeneratorTarget extends GeneratorTarget {
  _DirectoryGeneratorTarget(this.logger, this.dir) {
    dir.createSync();
  }

  final Logger logger;
  final io.Directory dir;

  @override
  Future<io.File> createFile(String filePath, List<int> contents) {
    final file = io.File(path.join(dir.path, filePath));

    return file
        .create(recursive: true)
        .then<io.File>((_) => file.writeAsBytes(contents));
  }
}
