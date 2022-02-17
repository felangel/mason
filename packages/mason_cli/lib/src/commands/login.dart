import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_auth/mason_auth.dart';
import 'package:mason_cli/src/command.dart';

/// {@template login_command}
/// `mason login` command which allows users to authenticate.
/// {@endtemplate}
class LoginCommand extends MasonCommand {
  /// {@macro login_command}
  LoginCommand({Logger? logger, MasonAuth? masonAuth})
      : _masonAuth = masonAuth ?? MasonAuth(),
        super(logger: logger);

  final MasonAuth _masonAuth;

  @override
  final String description = 'Log into brickhub.dev.';

  @override
  final String name = 'login';

  @override
  Future<int> run() async {
    final user = _masonAuth.currentUser;
    if (user != null) {
      logger
        ..info('You are already logged in as <${user.email}>')
        ..info("Run 'mason logout' to log out and try again.");
      return ExitCode.success.code;
    }

    final email = logger.prompt('email:');
    final password = logger.prompt('password:', hidden: true);

    final loginDone = logger.progress('Logging into brickhub.dev');
    try {
      final user = await _masonAuth.login(email: email, password: password);
      loginDone('Logged into brickhub.dev');
      logger.success('You are now logged in as <${user.email}>');
      return ExitCode.success.code;
    } on MasonAuthLoginFailure catch (error) {
      loginDone();
      logger.err(error.message);
      return ExitCode.software.code;
    }
  }
}
