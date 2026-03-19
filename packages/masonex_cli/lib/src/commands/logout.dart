import 'package:masonex/masonex.dart' hide packageVersion;
import 'package:masonex_api/masonex_api.dart';
import 'package:masonex_cli/src/command.dart';
import 'package:masonex_cli/src/command_runner.dart';

/// {@template logout_command}
/// `masonex logout` command which allows users to log out.
/// {@endtemplate}
class LogoutCommand extends MasonexCommand {
  /// {@macro logout_command}
  LogoutCommand({super.logger, MasonexApiBuilder? masonexApiBuilder})
      : _masonexApiBuilder = masonexApiBuilder ?? MasonexApi.new;

  final MasonexApiBuilder _masonexApiBuilder;

  @override
  final String description = 'Log out of brickhub.dev.';

  @override
  final String name = 'logout';

  @override
  Future<int> run() async {
    final masonexApi = _masonexApiBuilder();
    final user = masonexApi.currentUser;
    if (user == null) {
      logger.info('You are already logged out.');
      masonexApi.close();
      return ExitCode.success.code;
    }

    final progress = logger.progress('Logging out of brickhub.dev.');
    try {
      masonexApi.logout();
      progress.complete('Logged out of brickhub.dev');
      return ExitCode.success.code;
    } catch (error) {
      progress.fail();
      logger.err('$error');
      return ExitCode.software.code;
    } finally {
      masonexApi.close();
    }
  }
}
