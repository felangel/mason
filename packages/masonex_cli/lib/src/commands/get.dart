import 'package:masonex/masonex.dart';
import 'package:masonex_cli/src/command.dart';
import 'package:masonex_cli/src/install_brick.dart';

/// {@template get_command}
/// `masonex get` command which gets all bricks.
/// {@endtemplate}
class GetCommand extends MasonexCommand with InstallBrickMixin {
  /// {@macro get_command}
  GetCommand({super.logger});

  @override
  final String description = 'Gets all bricks in the nearest masonex.yaml.';

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
