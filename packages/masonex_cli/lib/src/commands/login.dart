import 'package:masonex/masonex.dart' hide packageVersion;
import 'package:masonex_api/masonex_api.dart';
import 'package:masonex_cli/src/command.dart';
import 'package:masonex_cli/src/command_runner.dart';

/// {@template login_command}
/// `masonex login` command which allows users to authenticate.
/// {@endtemplate}
class LoginCommand extends MasonexCommand {
  /// {@macro login_command}
  LoginCommand({super.logger, MasonexApiBuilder? masonexApiBuilder})
      : _masonexApiBuilder = masonexApiBuilder ?? MasonexApi.new;

  final MasonexApiBuilder _masonexApiBuilder;

  @override
  final String description = 'Log into brickhub.dev.';

  @override
  final String name = 'login';

  @override
  Future<int> run() async {
    final masonexApi = _masonexApiBuilder();
    final user = masonexApi.currentUser;
    if (user != null) {
      logger
        ..info('You are already logged in as <${user.email}>')
        ..info("Run 'masonex logout' to log out and try again.");
      return ExitCode.success.code;
    }

    final email = logger.prompt('email:');
    final password = logger.prompt('password:', hidden: true);

    final progress = logger.progress('Logging into brickhub.dev');
    try {
      final user = await masonexApi.login(email: email, password: password);
      progress.complete('Logged into brickhub.dev');
      logger.success('You are now logged in as <${user.email}>');
      return ExitCode.success.code;
    } on MasonexApiLoginFailure catch (error) {
      progress.fail();
      logger.err(error.message);
      return ExitCode.software.code;
    } finally {
      masonexApi.close();
    }
  }
}
