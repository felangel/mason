import 'dart:convert';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/install_brick.dart';
import 'package:path/path.dart' as p;

/// {@template add_command}
/// `mason add` command which adds a brick.
/// {@endtemplate}
class AddCommand extends MasonCommand with InstallBrickMixin {
  /// {@macro add_command}
  AddCommand({super.logger}) {
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
    if (results.rest.isEmpty) usageException('brick name is required.');

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
      if (results.rest.length > 2) {
        usageException(
          'Too many arguments, expected arguments <name> <version>',
        );
      }
      final version = results.rest.length == 2 ? results.rest.last : 'any';
      brick = Brick(name: name, location: BrickLocation(version: version));
    }
    final masonYaml = isGlobal ? globalMasonYaml : localMasonYaml;
    final masonYamlFile = isGlobal ? globalMasonYamlFile : localMasonYamlFile;
    final bricksJson = isGlobal ? globalBricksJson : localBricksJson;
    final masonLockJson = isGlobal ? globalMasonLockJson : localMasonLockJson;
    final masonLockJsonFile =
        isGlobal ? globalMasonLockJsonFile : localMasonLockJsonFile;
    if (bricksJson == null) throw const MasonYamlNotFoundException();
    final cachedPath = bricksJson.getPath(brick);
    if (cachedPath != null) {
      logger.info(
        '''${red.wrap(styleBold.wrap('conflict'))} ${darkGray.wrap(cachedPath)}''',
      );
      final confirm = logger.confirm(
        lightYellow.wrap('Overwrite ${brick.name}?'),
      );
      if (!confirm) return ExitCode.success.code;

      bricksJson.remove(brick);
      await bricksJson.flush();

      final bricks = Map.of(masonYaml.bricks)
        ..removeWhere((key, value) => key == brick.name);
      masonYamlFile.writeAsStringSync(Yaml.encode(MasonYaml(bricks).toJson()));

      final lockedBricks = {...masonLockJson.bricks}
        ..removeWhere((key, value) => key == brick.name);
      await masonLockJsonFile.writeAsString(
        json.encode(MasonLockJson(bricks: lockedBricks).toJson()),
      );
    }

    final progress = logger.progress('Installing ${brick.name}');
    final cachedBrick = await _addBrick(brick, global: isGlobal);
    final file = File(p.join(cachedBrick.path, BrickYaml.file));
    final generator = await MasonGenerator.fromBrick(
      Brick.path(cachedBrick.path),
    );

    progress.update('Building ${brick.name}');
    try {
      await generator.hooks.compile();
    } catch (_) {
      progress.fail();
      rethrow;
    }

    final brickYaml = checkedYamlDecode(
      file.readAsStringSync(),
      (m) => BrickYaml.fromJson(m!),
    ).copyWith(path: file.path);

    final location = brick.location.version != null
        ? BrickLocation(version: '^${brickYaml.version}')
        : brick.location.path != null
            ? BrickLocation(
                path: p.relative(
                  canonicalize(Directory(brick.location.path!).absolute.path),
                  from: masonYamlFile.parent.path,
                ),
              )
            : brick.location;
    final bricks = Map.of(masonYaml.bricks)..addAll({name: location});
    progress.update('Adding ${brickYaml.name}');
    try {
      await masonYamlFile.writeAsString(
        Yaml.encode(MasonYaml(bricks).toJson()),
      );
      progress.complete('Added ${brickYaml.name}');
    } catch (_) {
      progress.fail();
      rethrow;
    }
    return ExitCode.success.code;
  }

  /// Installs a specific brick and returns the [CachedBrick] reference.
  Future<CachedBrick> _addBrick(Brick brick, {bool global = false}) async {
    final bricksJson = global ? globalBricksJson : localBricksJson;
    if (bricksJson == null) throw const MasonYamlNotFoundException();

    final masonLockJsonFile =
        global ? globalMasonLockJsonFile : localMasonLockJsonFile;
    final masonLockJson = global ? globalMasonLockJson : localMasonLockJson;
    final location = resolveBrickLocation(
      location: brick.location,
      lockedLocation: masonLockJson.bricks[brick.name],
    );
    final cachedBrick = await bricksJson.add(
      Brick(name: brick.name, location: location),
    );
    await bricksJson.flush();
    await masonLockJsonFile.writeAsString(
      json.encode(
        MasonLockJson(
          bricks: {
            ...masonLockJson.bricks,
            brick.name!: cachedBrick.brick.location,
          },
        ),
      ),
    );
    return cachedBrick;
  }
}
