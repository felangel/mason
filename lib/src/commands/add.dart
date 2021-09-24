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
/// `mason add` command which adds a brick to the mason.yaml.
/// {@endtemplate}
class AddCommand extends MasonCommand {
  /// {@macro add_command}
  AddCommand({Logger? logger}) : super(logger: logger) {
    argParser
      ..addOption(
        'source',
        abbr: 's',
        defaultsTo: 'path',
        allowed: ['git', 'path'],
        allowedHelp: {
          'git': 'git url for remote brick template',
          'path': 'path to local brick template'
        },
        help: 'Adds a brick to the mason.yaml.',
      )
      ..addOption('path', help: 'Optional git path')
      ..addOption('ref', help: 'Optional git ref (commit hash, tag, etc.)');
  }

  @override
  final String description = 'Adds a brick to the mason.yaml.';

  @override
  final String name = 'add';

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) {
      throw UsageException('path to the brick is required.', usage);
    }

    final location = results.rest.first;
    final bricksJson = localBricksJson;
    if (bricksJson == null) throw const MasonYamlNotFoundException();

    final addDone = logger.progress('Adding brick at $location');

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

    final bricks = Map.of(masonYaml.bricks)..addAll({brickYaml.name: brick});
    try {
      if (!masonYaml.bricks.containsKey(name)) {
        await masonYamlFile.writeAsString(
          Yaml.encode(MasonYaml(bricks).toJson()),
        );
      }
      await bricksJson.add(brick);
      await bricksJson.flush();
    } finally {
      addDone();
    }
    return ExitCode.success.code;
  }
}
