import 'package:io/io.dart';
import 'package:mason/mason.dart';

import '../command.dart';

/// {@template get_command}
/// `mason get` command which gets all bricks.
/// {@endtemplate}
class GetCommand extends MasonCommand {
  /// {@macro get_command}
  GetCommand({Logger? logger}) : super(logger: logger);

  @override
  final String description = 'Gets all bricks.';

  @override
  final String name = 'get';

  @override
  Future<int> run() async {
    final bricksJson = localBricksJson;
    if (bricksJson == null) throw const MasonYamlNotFoundException();
    final getDone = logger.progress('getting bricks');
    if (masonYaml.bricks.values.isNotEmpty) {
      await Future.forEach(masonYaml.bricks.values, bricksJson.add);
      await bricksJson.flush();
    }
    getDone();
    return ExitCode.success.code;
  }
}
