import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:universal_io/io.dart';

import 'commands/commands.dart';
import 'exception.dart';
import 'io.dart';
import 'logger.dart';
import 'version.dart';

/// The package name.
const packageName = 'mason';

/// {@template mason_command_runner}
/// A [CommandRunner] for the Mason CLI.
/// {@endtemplate}
class MasonCommandRunner extends CommandRunner<int> {
  /// {@macro mason_command_runner}
  MasonCommandRunner({Logger? logger, PubUpdater? pubUpdater})
      : _logger = logger ?? Logger(),
        _pubUpdater = pubUpdater ?? PubUpdater(),
        super(packageName, '⛏️  mason \u{2022} lay the foundation!') {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the current version.',
    );
    addCommand(AddCommand(logger: _logger));
    addCommand(CacheCommand(logger: _logger));
    addCommand(BundleCommand(logger: _logger));
    addCommand(GetCommand(logger: _logger));
    addCommand(InitCommand(logger: _logger));
    addCommand(ListCommand(logger: _logger));
    addCommand(MakeCommand(logger: _logger));
    addCommand(NewCommand(logger: _logger));
    addCommand(RemoveCommand(logger: _logger));
  }

  final Logger _logger;
  final PubUpdater _pubUpdater;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      return await runCommand(parse(args)) ?? ExitCode.success.code;
    } on FormatException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on MasonException catch (e) {
      _logger.err(e.message);
      return ExitCode.usage.code;
    } on ProcessException catch (error) {
      _logger.err(error.message);
      return ExitCode.unavailable.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    int? exitCode = ExitCode.unavailable.code;
    if (topLevelResults['version'] == true) {
      _logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }
    await _checkForUpdates();
    return exitCode;
  }

  Future<void> _checkForUpdates() async {
    try {
      final latestVersion = await _pubUpdater.getLatestVersion(packageName);
      final isUpToDate = packageVersion == latestVersion;
      if (!isUpToDate) {
        _logger
          ..info('')
          ..info('''
+------------------------------------------------------------------------------------+
|                                                                                    |
|                   ${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}                    |
|       ${lightYellow.wrap('Changelog:')} ${lightCyan.wrap('https://github.com/felangel/mason/releases/tag/v$latestVersion')}      |
|                                                                                    |
+------------------------------------------------------------------------------------+
''');
        final response = _logger.prompt('Would you like to update? (y/n) ');
        if (response.isYes()) {
          final updateDone = _logger.progress('Updating to $latestVersion');
          await _pubUpdater.update(packageName: packageName);
          updateDone('Updated to $latestVersion');
        }
      }
    } catch (_) {}
  }
}

extension on String {
  bool isYes() {
    final normalized = toLowerCase().trim();
    return normalized == 'y' || normalized == 'yes';
  }
}
