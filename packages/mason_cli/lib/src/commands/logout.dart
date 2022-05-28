import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/command.dart';

/// {@template logout_command}
/// `mason logout` command which allows users to log out.
/// {@endtemplate}
class LogoutCommand extends MasonCommand {
  /// {@macro logout_command}
  LogoutCommand({Logger? logger, MasonApi? masonApi})
      : _masonApi = masonApi ?? MasonApi(),
        super(logger: logger);

  final MasonApi _masonApi;

  @override
  final String description = 'Log out of brickhub.dev.';

  @override
  final String name = 'logout';

  @override
  Future<int> run() async {
    final user = _masonApi.currentUser;
    if (user == null) {
      logger.info('You are already logged out.');
      return ExitCode.success.code;
    }

    final logoutProgress = logger.progress('Logging out of brickhub.dev.');
    try {
      _masonApi.logout();
      logoutProgress.complete('Logged out of brickhub.dev');
      return ExitCode.success.code;
    } catch (error) {
      logoutProgress.fail();
      logger.err('$error');
      return ExitCode.software.code;
    }
  }
}
