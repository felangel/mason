import 'package:masonex/masonex.dart' hide packageVersion;
import 'package:mason_api/mason_api.dart';
import 'package:masonex_cli/src/command.dart';
import 'package:masonex_cli/src/command_runner.dart';

/// {@template logout_command}
/// `masonex logout` command which allows users to log out.
/// {@endtemplate}
class LogoutCommand extends MasonexCommand {
  /// {@macro logout_command}
  LogoutCommand({super.logger, MasonApiBuilder? masonApiBuilder})
      : _masonApiBuilder = masonApiBuilder ?? MasonApi.new;

  final MasonApiBuilder _masonApiBuilder;

  @override
  final String description = 'Log out of brickhub.dev.';

  @override
  final String name = 'logout';

  @override
  Future<int> run() async {
    final masonApi = _masonApiBuilder();
    final user = masonApi.currentUser;
    if (user == null) {
      logger.info('You are already logged out.');
      masonApi.close();
      return ExitCode.success.code;
    }

    final progress = logger.progress('Logging out of brickhub.dev.');
    try {
      masonApi.logout();
      progress.complete('Logged out of brickhub.dev');
      return ExitCode.success.code;
    } catch (error) {
      progress.fail();
      logger.err('$error');
      return ExitCode.software.code;
    } finally {
      masonApi.close();
    }
  }
}
