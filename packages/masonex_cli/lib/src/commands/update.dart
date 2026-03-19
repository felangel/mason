import 'dart:io';

import 'package:masonex/masonex.dart' hide packageVersion;
import 'package:masonex_cli/src/command.dart';
import 'package:masonex_cli/src/command_runner.dart';
import 'package:masonex_cli/src/version.dart';
import 'package:pub_updater/pub_updater.dart';

/// {@template update_command}
/// `masonex update` command which updates masonex.
/// {@endtemplate}
class UpdateCommand extends MasonexCommand {
  /// {@macro update_command}
  UpdateCommand({
    required PubUpdater pubUpdater,
    super.logger,
  }) : _pubUpdater = pubUpdater;

  final PubUpdater _pubUpdater;

  @override
  final String description = 'Update masonex.';

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
      logger.info('masonex is already at the latest version.');
      return ExitCode.success.code;
    }

    final progress = logger.progress('Updating to $latestVersion');
    late final ProcessResult result;
    try {
      result = await _pubUpdater.update(
        packageName: packageName,
        versionConstraint: latestVersion,
      );
    } catch (error) {
      progress.fail();
      logger.err('$error');
      return ExitCode.software.code;
    }

    if (result.exitCode != ExitCode.success.code) {
      progress.fail('Unable to update to $latestVersion');
      logger.err('${result.stderr}');
      return ExitCode.software.code;
    }

    progress.complete('Updated to $latestVersion');

    return ExitCode.success.code;
  }
}
