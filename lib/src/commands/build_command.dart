import 'dart:io';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:io/io.dart' as io;
import 'package:mason/src/generator.dart';
import 'package:mason/src/mason_configuration.dart';
import 'package:path/path.dart' as path;
import 'package:args/command_runner.dart';

import '../logger.dart';

/// {@template build_command}
/// `mason build` command which generates code based on a pre-existing template.
/// {@endtemplate}
class BuildCommand extends Command<dynamic> {
  /// {@macro build_command}
  BuildCommand(this._logger);

  final Logger _logger;

  @override
  final String description = 'Generate code using an existing template.';

  @override
  final String name = 'build';

  Directory _cwd;

  /// Return the current working directory.
  Directory get cwd => _cwd ?? Directory.current;

  /// An override for the directory to generate into; public for testing.
  set cwd(Directory value) => _cwd = value;

  @override
  void run() async {
    final masonConfigFile = MasonConfiguration.findNearest(cwd);
    if (masonConfigFile == null) {
      _logger.err(
        'missing mason.yaml at ${path.join(cwd.path, 'mason.yaml')}',
      );
      return;
    }
    final masonConfigContent = masonConfigFile.existsSync()
        ? masonConfigFile.readAsStringSync()
        : null;
    if (masonConfigContent == null || masonConfigContent.isEmpty) {
      _logger.err(
        'malformed mason.yaml at ${path.join(cwd.path, 'mason.yaml')}',
      );
      return;
    }
    final masonConfig = checkedYamlDecode(
      masonConfigContent,
      (m) => MasonConfiguration.fromJson(m),
    );
    final args = argResults.rest;
    final template = masonConfig.templates[args.first];
    final dir = cwd;
    final target = _DirectoryGeneratorTarget(_logger, dir);

    if (template == null) {
      _logger
        ..err('Specify a template')
        ..info('')
        ..info(usage);
      exitCode = io.ExitCode.usage.code;
      return;
    }

    final fetchDone = _logger.progress('fetching template');
    Function generateDone;
    try {
      final generator = await MasonGenerator.fromTemplate(
        template,
        workingDirectory: masonConfigFile.parent.path,
      );
      fetchDone();
      final vars = <String, String>{};
      for (final variable in generator.vars) {
        final index = args.indexOf('--$variable');
        if (index != -1) {
          vars.addAll({variable: args[index + 1]});
        } else {
          vars.addAll({variable: _logger.prompt('$variable: ')});
        }
      }

      generateDone = _logger.progress('building ${generator.id}');
      await generator.generate(target, vars: vars);
      generateDone?.call();
      _logger.success('built ${generator.id} in ${target.dir.path}');
    } on Exception catch (e) {
      fetchDone();
      generateDone?.call();
      _logger.err(e.toString());
    }
  }
}

class _DirectoryGeneratorTarget extends GeneratorTarget {
  _DirectoryGeneratorTarget(this.logger, this.dir) {
    dir.createSync();
  }

  final Logger logger;
  final Directory dir;

  @override
  Future<File> createFile(String filePath, List<int> contents) {
    final file = File(path.join(dir.path, filePath));

    return file
        .create(recursive: true)
        .then<File>((_) => file.writeAsBytes(contents));
  }
}
