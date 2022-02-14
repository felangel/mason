import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/yaml_encode.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

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
      throw UsageException('bricks.json not found', usage);
    }

    late final Brick brick;

    final installDone = logger.progress('Installing brick from $location');
    try {
      if (results['source'] == 'path') {
        final file = File(p.join(location, BrickYaml.file));
        if (!file.existsSync()) {
          throw UsageException('brick not found at path $location', usage);
        }
        final brickYaml = checkedYamlDecode(
          file.readAsStringSync(),
          (m) => BrickYaml.fromJson(m!),
        ).copyWith(path: file.path);
        brick = Brick.path(name: brickYaml.name, path: file.parent.path);
        await bricksJson.add(brick);
      } else {
        final gitPath = GitPath(
          location,
          path: results['path'] as String?,
          ref: results['ref'] as String?,
        );
        brick = Brick.git(gitPath);
        try {
          await bricksJson.add(brick);
        } catch (_) {
          throw UsageException('brick not found at url $location', usage);
        }
      }
    } finally {
      installDone();
    }

    final targetMasonYaml = isGlobal ? globalMasonYaml : masonYaml;
    final targetMasonYamlFile = isGlobal ? globalMasonYamlFile : masonYamlFile;
    final bricks = Map.of(targetMasonYaml.bricks)
      ..addAll({brick.name: brick.location});
    final addDone = logger.progress('Adding ${brick.name}');
    try {
      if (!targetMasonYaml.bricks.containsKey(name)) {
        await targetMasonYamlFile.writeAsString(
          Yaml.encode(MasonYaml(bricks).toJson()),
        );
      }
      await bricksJson.add(brick);
      await bricksJson.flush();
      addDone('Added ${brick.name}');
    } catch (_) {
      addDone();
      rethrow;
    }
    return ExitCode.success.code;
  }
}
