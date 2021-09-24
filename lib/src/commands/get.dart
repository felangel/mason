import 'package:mason/mason.dart';

import '../command.dart';
import '../io.dart';

/// {@template get_command}
/// `mason get` command which gets all bricks.
/// {@endtemplate}
class GetCommand extends MasonCommand {
  /// {@macro get_command}
  GetCommand({Logger? logger}) : super(logger: logger);

  @override
  final String description = 'Gets all bricks in the nearest mason.yaml.';

  @override
  final String name = 'get';

  @override
  Future<int> run() async {
    final bricksJson = localBricksJson;
    if (bricksJson == null) throw const MasonYamlNotFoundException();
    final getDone = logger.progress('Getting bricks');
    try {
      if (masonYaml.bricks.values.isNotEmpty) {
        await Future.forEach(masonYaml.bricks.values, bricksJson.add);
      }
    } finally {
      await bricksJson.flush();
      getDone();
    }
    return ExitCode.success.code;
  }
}
