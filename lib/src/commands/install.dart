import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

import '../brick_yaml.dart';
import '../command.dart';
import '../mason_yaml.dart';
import '../yaml_encode.dart';

/// {@template install_command}
/// `mason install` command which installs a bricks globally.
/// {@endtemplate}
class InstallCommand extends MasonCommand {
  /// {@macro install_command}
  InstallCommand({Logger? logger}) : super(logger: logger) {
    argParser
      ..addOption(
        'source',
        abbr: 's',
        defaultsTo: 'git',
        allowed: ['git', 'path'],
        allowedHelp: {
          'git': 'git url for remote brick template',
          'path': 'path to local brick template'
        },
        help: 'Installs a brick globally.',
      )
      ..addOption('path', help: 'Optional git path')
      ..addOption('ref', help: 'Optional git ref (commit hash, tag, etc.)');
  }

  @override
  final String description = 'Installs a brick globally.';

  @override
  final String name = 'install';

  @override
  List<String> get aliases => ['i'];

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) {
      throw UsageException('path to the brick is required.', usage);
    }

    final location = results.rest.first;
    final bricksJson = globalBricksJson;
    final downloadDone = logger.progress('Downloading brick at $location');

    late final Brick brick;
    late final File file;

    if (results['source'] == 'path') {
      file = File(p.join(location, BrickYaml.file));
      if (!file.existsSync()) {
        throw UsageException('brick not found at path $location', usage);
      }
      brick = Brick(path: file.parent.path);
      await bricksJson.add(brick);
    } else {
      final gitPath = GitPath(
        location,
        path: results['path'] as String?,
        ref: results['ref'] as String?,
      );
      brick = Brick(git: gitPath);
      try {
        final directory = await bricksJson.add(brick);
        file = File(p.join(directory, gitPath.path, BrickYaml.file));
      } catch (_) {
        throw UsageException('brick not found at url $location', usage);
      }
    }

    final brickYaml = checkedYamlDecode(
      file.readAsStringSync(),
      (m) => BrickYaml.fromJson(m!),
    ).copyWith(path: file.path);

    downloadDone();
    final installDone = logger.progress('Installing ${brickYaml.name}');
    final bricks = Map.of(globalMasonYaml.bricks)
      ..addAll({brickYaml.name: brick});
    if (!globalMasonYaml.bricks.containsKey(name)) {
      globalMasonYamlFile.writeAsStringSync(
        Yaml.encode(MasonYaml(bricks).toJson()),
      );
    }
    await bricksJson.flush();
    installDone();
    return ExitCode.success.code;
  }
}
