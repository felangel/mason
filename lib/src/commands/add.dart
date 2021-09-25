import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

import '../brick_yaml.dart';
import '../command.dart';
import '../io.dart';
import '../mason_yaml.dart';
import '../yaml_encode.dart';

/// {@template add_command}
/// `mason add` command which adds a brick.
/// {@endtemplate}
class AddCommand extends MasonCommand {
  /// {@macro add_command}
  AddCommand({Logger? logger}) : super(logger: logger) {
    argParser
      ..addFlag(
        'global',
        abbr: 'g',
        help: 'Adds the brick globally.',
      )
      ..addOption(
        'source',
        abbr: 's',
        defaultsTo: 'path',
        allowed: ['git', 'path'],
        allowedHelp: {
          'git': 'git url for remote brick template',
          'path': 'path to local brick template'
        },
        help: 'The location of the brick.',
      )
      ..addOption('path', help: 'Optional git path')
      ..addOption('ref', help: 'Optional git ref (commit hash, tag, etc.)');
  }

  @override
  final String description = 'Adds a brick from a local or remote source.';

  @override
  final String name = 'add';

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) {
      throw UsageException('path to the brick is required.', usage);
    }

    final isGlobal = results['global'] == true;
    final location = results.rest.first;
    final bricksJson = isGlobal ? globalBricksJson : localBricksJson;
    if (bricksJson == null) {
      throw UsageException('brick not found at path $location', usage);
    }

    late final Brick brick;
    late final File file;

    final installDone = logger.progress('Installing brick from $location');
    try {
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
    } finally {
      installDone();
    }

    final brickYaml = checkedYamlDecode(
      file.readAsStringSync(),
      (m) => BrickYaml.fromJson(m!),
    ).copyWith(path: file.path);

    final targetMasonYaml = isGlobal ? globalMasonYaml : masonYaml;
    final targetMasonYamlFile = isGlobal ? globalMasonYamlFile : masonYamlFile;
    final bricks = Map.of(targetMasonYaml.bricks)
      ..addAll({brickYaml.name: brick});
    final addDone = logger.progress('Adding ${brickYaml.name}');
    try {
      if (!targetMasonYaml.bricks.containsKey(name)) {
        await targetMasonYamlFile.writeAsString(
          Yaml.encode(MasonYaml(bricks).toJson()),
        );
      }
      await bricksJson.add(brick);
      await bricksJson.flush();
      addDone('Added ${brickYaml.name}');
    } catch (_) {
      addDone();
      rethrow;
    }
    return ExitCode.success.code;
  }
}
