import 'package:io/io.dart';

import '../command.dart';

/// {@template install_command}
/// `mason install` command which installs all remote bricks.
/// {@endtemplate}
class InstallCommand extends MasonCommand {
  @override
  final String description = 'Installs all remote bricks';

  @override
  final String name = 'install';

  @override
  Future<int> run() async {
    return ExitCode.success.code;
  }
}
