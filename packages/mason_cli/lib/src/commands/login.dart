import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/command_runner.dart';

/// {@template login_command}
/// `mason login` command which allows users to authenticate.
/// {@endtemplate}
class LoginCommand extends MasonCommand {
  /// {@macro login_command}
  LoginCommand({super.logger, MasonApiBuilder? masonApiBuilder})
      : _masonApiBuilder = masonApiBuilder ?? MasonApi.new;

  final MasonApiBuilder _masonApiBuilder;

  @override
  final String description = 'Log into brickhub.dev.';

  @override
  final String name = 'login';

  @override
  Future<int> run() async {
    final masonApi = _masonApiBuilder();
    final user = masonApi.currentUser;
    if (user != null) {
      logger
        ..info('You are already logged in as <${user.email}>')
        ..info("Run 'mason logout' to log out and try again.");
      return ExitCode.success.code;
    }

    final email = logger.prompt('email:');
    final password = logger.prompt('password:', hidden: true);

    final progress = logger.progress('Logging into brickhub.dev');
    try {
      final user = await masonApi.login(email: email, password: password);
      progress.complete('Logged into brickhub.dev');
      logger.success('You are now logged in as <${user.email}>');
      return ExitCode.success.code;
    } on MasonApiLoginFailure catch (error) {
      progress.fail();
      logger.err(error.message);
      return ExitCode.software.code;
    } finally {
      masonApi.close();
    }
  }
}
