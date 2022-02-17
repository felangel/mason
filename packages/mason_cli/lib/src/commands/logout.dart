import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_auth/mason_auth.dart';
import 'package:mason_cli/src/command.dart';

/// {@template logout_command}
/// `mason logout` command which allows users to log out.
/// {@endtemplate}
class LogoutCommand extends MasonCommand {
  /// {@macro logout_command}
  LogoutCommand({Logger? logger, MasonAuth? masonAuth})
      : _masonAuth = masonAuth ?? MasonAuth(),
        super(logger: logger);

  final MasonAuth _masonAuth;

  @override
  final String description = 'Log out of brickhub.dev.';

  @override
  final String name = 'logout';

  @override
  Future<int> run() async {
    final user = _masonAuth.currentUser;
    if (user == null) {
      logger.info('You are already logged out.');
      return ExitCode.success.code;
    }

    final logoutDone = logger.progress('Logging out of brickhub.dev.');
    try {
      _masonAuth.logout();
      logoutDone('Logged out of brickhub.dev');
      return ExitCode.success.code;
    } catch (error) {
      logoutDone();
      logger.err('$error');
      return ExitCode.software.code;
    }
  }
}
