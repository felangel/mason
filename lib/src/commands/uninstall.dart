import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';

import '../command.dart';
import '../mason_yaml.dart';
import '../yaml_encode.dart';

/// {@template uninstall_command}
/// `mason uninstall` command which uninstalls a bricks globally.
/// {@endtemplate}
class UninstallCommand extends MasonCommand {
  /// {@macro uninstall_command}
  UninstallCommand({Logger? logger}) : super(logger: logger);

  @override
  final String description = 'Uninstalls a brick globally.';

  @override
  final String name = 'uninstall';

  @override
  List<String> get aliases => ['un'];

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) {
      throw UsageException('name of the brick is required.', usage);
    }

    final bricksJson = globalBricksJson;
    final brickName = results.rest.first;
    final brick = globalMasonYaml.bricks[brickName];
    if (brick == null) {
      throw UsageException('no brick named $brickName was found', usage);
    }

    final uninstallDone = logger.progress('Uninstalling $brickName');
    bricksJson.remove(brick);
    final bricks = Map.of(globalMasonYaml.bricks)
      ..removeWhere((key, value) => key == brickName);
    globalMasonYamlFile.writeAsStringSync(
      Yaml.encode(MasonYaml(bricks).toJson()),
    );

    await bricksJson.flush();
    uninstallDone();
    return ExitCode.success.code;
  }
}
