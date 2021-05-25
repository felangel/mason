import 'package:mason/mason.dart';

import '../command.dart';

/// {@template install_command}
/// `mason install` command which installs a bricks globally.
/// {@endtemplate}
class InstallCommand extends MasonCommand {
  /// {@macro install_command}
  InstallCommand({Logger? logger}) : super(logger: logger);

  @override
  final String description = 'Installs a brick globally';

  @override
  final String name = 'install';

  @override
  Future<int> run() async => 0;
}
