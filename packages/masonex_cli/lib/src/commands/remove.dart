import 'dart:convert';

import 'package:masonex/masonex.dart';
import 'package:masonex_cli/src/command.dart';

/// {@template remove_command}
/// `masonex remove` command which removes a brick.
/// {@endtemplate}
class RemoveCommand extends MasonexCommand {
  /// {@macro remove_command}
  RemoveCommand({super.logger}) {
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
    final masonexYaml = isGlobal ? globalMasonexYaml : localMasonexYaml;
    final brickLocation = masonexYaml.bricks[brickName];
    if (bricksJson == null || brickLocation == null) {
      usageException('no brick named $brickName was found');
    }

    final masonexLockJsonFile =
        isGlobal ? globalMasonexLockJsonFile : localMasonexLockJsonFile;
    final masonexLockJson = isGlobal ? globalMasonexLockJson : localMasonexLockJson;

    final masonexYamlFile = isGlobal ? globalMasonexYamlFile : localMasonexYamlFile;
    final progress = logger.progress('Removing $brickName');
    try {
      bricksJson.remove(Brick(name: brickName, location: brickLocation));
      final bricks = Map.of(masonexYaml.bricks)
        ..removeWhere((key, value) => key == brickName);

      masonexYamlFile.writeAsStringSync(Yaml.encode(MasonexYaml(bricks).toJson()));

      await bricksJson.flush();

      if (masonexLockJson.bricks.containsKey(brickName)) {
        final lockedBricks = {...masonexLockJson.bricks}
          ..removeWhere((key, value) => key == brickName);
        await masonexLockJsonFile.writeAsString(
          json.encode(MasonexLockJson(bricks: lockedBricks).toJson()),
        );
      }

      progress.complete('Removed $brickName');
    } catch (_) {
      progress.fail();
      rethrow;
    }

    return ExitCode.success.code;
  }
}
