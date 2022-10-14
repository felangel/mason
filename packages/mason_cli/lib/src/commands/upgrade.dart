import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/install_brick.dart';

/// {@template upgrade_command}
/// `mason upgrade` command which upgrades bricks to their latest versions.
/// {@endtemplate}
class UpgradeCommand extends MasonCommand with InstallBrickMixin {
  /// {@macro upgrade_command}
  UpgradeCommand({Logger? logger}) : super(logger: logger) {
    argParser.addFlag(
      'global',
      abbr: 'g',
      help: 'Upgrades globally installed bricks.',
    );
  }

  @override
  final String description = 'Upgrade bricks to their latest versions.';

  @override
  final String name = 'upgrade';

  @override
  Future<int> run() async {
    final isGlobal = results['global'] == true;
    await getBricks(upgrade: true, global: isGlobal);
    return ExitCode.success.code;
  }
}
