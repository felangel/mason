import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/install_brick.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

/// {@template add_command}
/// `mason add` command which adds a brick.
/// {@endtemplate}
class AddCommand extends MasonCommand with InstallBrickMixin {
  /// {@macro add_command}
  AddCommand({Logger? logger}) : super(logger: logger) {
    argParser
      ..addFlag(
        'global',
        abbr: 'g',
        help: 'Adds the brick globally.',
      )
      ..addOption('git-url', help: 'Git URL of the brick')
      ..addOption('git-ref', help: 'Git branch or commit to be used')
      ..addOption('git-path', help: 'Path of the brick in the git repository')
      ..addOption('path', help: 'Local path of the brick');
  }

  @override
  final String description = 'Adds a brick from a local or remote source.';

  @override
  final String name = 'add';

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) {
      throw UsageException('brick name is required.', usage);
    }

    final name = results.rest.first;
    final gitUrl = results['git-url'] as String?;
    final path = results['path'] as String?;
    final isGlobal = results['global'] == true;

    late final Brick brick;
    if (path != null) {
      brick = Brick(name: name, location: BrickLocation(path: path));
    } else if (gitUrl != null) {
      brick = Brick(
        name: name,
        location: BrickLocation(
          git: GitPath(
            gitUrl,
            path: results['git-path'] as String?,
            ref: results['git-ref'] as String?,
          ),
        ),
      );
    } else {
      brick = Brick(name: name, location: const BrickLocation(version: 'any'));
    }

    final cachedBrick = await addBrick(brick, global: isGlobal);
    final file = File(p.join(cachedBrick.path, BrickYaml.file));

    final brickYaml = checkedYamlDecode(
      file.readAsStringSync(),
      (m) => BrickYaml.fromJson(m!),
    ).copyWith(path: file.path);

    final targetMasonYaml = isGlobal ? globalMasonYaml : masonYaml;
    final targetMasonYamlFile = isGlobal ? globalMasonYamlFile : masonYamlFile;
    final location = brick.location.version != null
        ? BrickLocation(version: '^${brickYaml.version}')
        : brick.location;
    final bricks = Map.of(targetMasonYaml.bricks)..addAll({name: location});
    final addDone = logger.progress('Adding ${brickYaml.name}');
    try {
      if (!targetMasonYaml.bricks.containsKey(name)) {
        await targetMasonYamlFile.writeAsString(
          Yaml.encode(MasonYaml(bricks).toJson()),
        );
      }
      addDone('Added ${brickYaml.name}');
    } catch (_) {
      addDone();
      rethrow;
    }
    return ExitCode.success.code;
  }
}
