import 'dart:convert';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:masonex/masonex.dart';
import 'package:masonex_cli/src/command.dart';
import 'package:masonex_cli/src/install_brick.dart';
import 'package:path/path.dart' as p;

/// {@template add_command}
/// `masonex add` command which adds a brick.
/// {@endtemplate}
class AddCommand extends MasonexCommand with InstallBrickMixin {
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
    final masonexYaml = isGlobal ? globalMasonexYaml : localMasonexYaml;
    final masonexYamlFile = isGlobal ? globalMasonexYamlFile : localMasonexYamlFile;
    final bricksJson = isGlobal ? globalBricksJson : localBricksJson;
    final masonexLockJson = isGlobal ? globalMasonexLockJson : localMasonexLockJson;
    final masonexLockJsonFile =
        isGlobal ? globalMasonexLockJsonFile : localMasonexLockJsonFile;
    if (bricksJson == null) throw const MasonexYamlNotFoundException();
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

      final bricks = Map.of(masonexYaml.bricks)
        ..removeWhere((key, value) => key == brick.name);
      masonexYamlFile.writeAsStringSync(Yaml.encode(MasonexYaml(bricks).toJson()));

      final lockedBricks = {...masonexLockJson.bricks}
        ..removeWhere((key, value) => key == brick.name);
      await masonexLockJsonFile.writeAsString(
        json.encode(MasonexLockJson(bricks: lockedBricks).toJson()),
      );
    }

    final progress = logger.progress('Installing ${brick.name}');
    final cachedBrick = await _addBrick(brick, global: isGlobal);
    final file = File(p.join(cachedBrick.path, BrickYaml.file));
    final generator = await MasonexGenerator.fromBrick(
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
                  from: masonexYamlFile.parent.path,
                ),
              )
            : brick.location;
    final bricks = Map.of(masonexYaml.bricks)..addAll({name: location});
    progress.update('Adding ${brickYaml.name}');
    try {
      await masonexYamlFile.writeAsString(
        Yaml.encode(MasonexYaml(bricks).toJson()),
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
    if (bricksJson == null) throw const MasonexYamlNotFoundException();

    final masonexLockJsonFile =
        global ? globalMasonexLockJsonFile : localMasonexLockJsonFile;
    final masonexLockJson = global ? globalMasonexLockJson : localMasonexLockJson;
    final location = resolveBrickLocation(
      location: brick.location,
      lockedLocation: masonexLockJson.bricks[brick.name],
    );
    final cachedBrick = await bricksJson.add(
      Brick(name: brick.name, location: location),
    );
    await bricksJson.flush();
    await masonexLockJsonFile.writeAsString(
      json.encode(
        MasonexLockJson(
          bricks: {
            ...masonexLockJson.bricks,
            brick.name!: cachedBrick.brick.location,
          },
        ),
      ),
    );
    return cachedBrick;
  }
}
