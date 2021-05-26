import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

import '../brick_yaml.dart';
import '../command.dart';
import '../mason_yaml.dart';

/// {@template install_command}
/// `mason install` command which installs a bricks globally.
/// {@endtemplate}
class InstallCommand extends MasonCommand {
  /// {@macro install_command}
  InstallCommand({Logger? logger}) : super(logger: logger);

  @override
  final String description = 'Installs a brick globally';

  @override
  final String name = 'install';

  @override
  List<String> get aliases => ['i'];

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) {
      throw UsageException('path to the brick is required.', usage);
    }
    final path = results.rest.first;
    final downloadDone = logger.progress('Downloading brick at $path');
    final file = File(p.join(path, BrickYaml.file));
    final isLocal = file.existsSync();

    late final Brick brick;
    late final BrickYaml brickYaml;

    if (isLocal) {
      brick = Brick(path: file.path);
      brickYaml = checkedYamlDecode(
        file.readAsStringSync(),
        (m) => BrickYaml.fromJson(m!),
      ).copyWith(path: file.path);
    }
    downloadDone();
    final installDone = logger.progress('Installing ${brickYaml.name}');
    await cacheBrick(brick);
    await writeCacheToBricksJson();
    installDone();
    return ExitCode.success.code;
  }
}
