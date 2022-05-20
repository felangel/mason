import 'dart:convert';

import 'package:args/command_runner.dart';
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
      throw UsageException('name of the brick is required.', usage);
    }

    final brickName = results.rest.first;
    final isGlobal = results['global'] == true;
    final bricksJson = isGlobal ? globalBricksJson : localBricksJson;
    final targetMasonYaml = isGlobal ? globalMasonYaml : masonYaml;
    final brickLocation = targetMasonYaml.bricks[brickName];
    if (bricksJson == null || brickLocation == null) {
      throw UsageException('no brick named $brickName was found', usage);
    }

    final lockFile = isGlobal ? globalMasonLockJsonFile : masonLockJsonFile;
    final lockJson = isGlobal ? globalMasonLockJson : masonLockJson;

    final targetMasonYamlFile = isGlobal ? globalMasonYamlFile : masonYamlFile;
    final removeDone = logger.progress('Removing $brickName');
    try {
      bricksJson.remove(Brick(name: brickName, location: brickLocation));
      final bricks = Map.of(targetMasonYaml.bricks)
        ..removeWhere((key, value) => key == brickName);

      targetMasonYamlFile.writeAsStringSync(
        Yaml.encode(MasonYaml(bricks).toJson()),
      );

      await bricksJson.flush();

      if (lockJson.bricks.containsKey(brickName)) {
        final lockedBricks = {...lockJson.bricks}
          ..removeWhere((key, value) => key == brickName);
        await lockFile.writeAsString(
          json.encode(MasonLockJson(bricks: lockedBricks).toJson()),
        );
      }

      removeDone.complete('Removed $brickName');
    } catch (_) {
      removeDone.fail();
      rethrow;
    }

    return ExitCode.success.code;
  }
}
