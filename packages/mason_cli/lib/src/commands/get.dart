import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/get_bricks.dart';

/// {@template get_command}
/// `mason get` command which gets all bricks.
/// {@endtemplate}
class GetCommand extends MasonCommand with GetBricksMixin {
  /// {@macro get_command}
  GetCommand({Logger? logger}) : super(logger: logger);

  @override
  final String description = 'Gets all bricks in the nearest mason.yaml.';

  @override
  final String name = 'get';

  @override
  Future<int> run() async {
    await getBricks();
    return ExitCode.success.code;
  }
}
