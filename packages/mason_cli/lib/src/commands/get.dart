import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/install_brick.dart';

/// {@template get_command}
/// `mason get` command which gets all bricks.
/// {@endtemplate}
class GetCommand extends MasonCommand with InstallBrickMixin {
  /// {@macro get_command}
  GetCommand({super.logger});

  @override
  final String description = 'Gets all bricks in the nearest mason.yaml.';

  @override
  final String name = 'get';

  @override
  Future<int> run() async {
    final progress = logger.progress('Getting bricks');
    try {
      await getBricks();
    } catch (_) {
      progress.fail();
      rethrow;
    }
    progress.complete('Got bricks');
    return ExitCode.success.code;
  }
}
