import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/command_runner.dart';
import 'package:mason_cli/src/version.dart';
import 'package:pub_updater/pub_updater.dart';

/// {@template update_command}
/// `mason update` command which updates mason.
/// {@endtemplate}
class UpdateCommand extends MasonCommand {
  /// {@macro update_command}
  UpdateCommand({
    required PubUpdater pubUpdater,
    Logger? logger,
  })  : _pubUpdater = pubUpdater,
        super(logger: logger);

  final PubUpdater _pubUpdater;

  @override
  final String description = 'Update mason.';

  @override
  final String name = 'update';

  @override
  Future<int> run() async {
    final updateCheckProgress = logger.progress('Checking for updates');
    late final String latestVersion;
    try {
      latestVersion = await _pubUpdater.getLatestVersion(packageName);
    } catch (error) {
      updateCheckProgress.fail();
      logger.err('$error');
      return ExitCode.software.code;
    }
    updateCheckProgress.complete('Checked for updates');

    final isUpToDate = packageVersion == latestVersion;
    if (isUpToDate) {
      logger.info('mason is already at the latest version.');
      return ExitCode.success.code;
    }

    final updateProgress = logger.progress('Updating to $latestVersion');
    try {
      await _pubUpdater.update(packageName: packageName);
    } catch (error) {
      updateProgress.fail();
      logger.err('$error');
      return ExitCode.software.code;
    }
    updateProgress.complete('Updated to $latestVersion');

    return ExitCode.success.code;
  }
}
