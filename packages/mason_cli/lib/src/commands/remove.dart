import 'dart:convert';

import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';

/// {@template remove_command}
/// `mason remove` command which removes a brick.
/// {@endtemplate}
class RemoveCommand extends MasonCommand {
  /// {@macro remove_command}
  RemoveCommand({Logger? logger}) : super(logger: logger) {
    argParser.addFlag(
      'global',
      abbr: 'g',
      help: 'Removes the brick globally.',
    );
  }

  @override
  final String description = 'Removes a brick.';

  @override
  final String name = 'remove';

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) {
      usageException('name of the brick is required.');
    }

    final brickName = results.rest.first;
    final isGlobal = results['global'] == true;
    final bricksJson = isGlobal ? globalBricksJson : localBricksJson;
    final masonYaml = isGlobal ? globalMasonYaml : localMasonYaml;
    final brickLocation = masonYaml.bricks[brickName];
    if (bricksJson == null || brickLocation == null) {
      usageException('no brick named $brickName was found');
    }

    final masonLockJsonFile =
        isGlobal ? globalMasonLockJsonFile : localMasonLockJsonFile;
    final masonLockJson = isGlobal ? globalMasonLockJson : localMasonLockJson;

    final masonYamlFile = isGlobal ? globalMasonYamlFile : localMasonYamlFile;
    final removeProgress = logger.progress('Removing $brickName');
    try {
      bricksJson.remove(Brick(name: brickName, location: brickLocation));
      final bricks = Map.of(masonYaml.bricks)
        ..removeWhere((key, value) => key == brickName);

      masonYamlFile.writeAsStringSync(Yaml.encode(MasonYaml(bricks).toJson()));

      await bricksJson.flush();

      if (masonLockJson.bricks.containsKey(brickName)) {
        final lockedBricks = {...masonLockJson.bricks}
          ..removeWhere((key, value) => key == brickName);
        await masonLockJsonFile.writeAsString(
          json.encode(MasonLockJson(bricks: lockedBricks).toJson()),
        );
      }

      removeProgress.complete('Removed $brickName');
    } catch (_) {
      removeProgress.fail();
      rethrow;
    }

    return ExitCode.success.code;
  }
}
