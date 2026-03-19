import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:masonex/masonex.dart' hide packageVersion;
import 'package:masonex/masonex.dart' as masonex;
import 'package:masonex_api/masonex_api.dart';
import 'package:masonex_cli/src/commands/commands.dart';
import 'package:masonex_cli/src/version.dart';
import 'package:pub_updater/pub_updater.dart';

/// Type definition for `MasonexApi.new`.
typedef MasonexApiBuilder = MasonexApi Function({Uri? hostedUri});

/// The package name.
const packageName = 'masonex_cli';

/// The executable name.
const executableName = 'masonex';

/// {@template masonex_command_runner}
/// A [CommandRunner] for the Masonex CLI.
/// {@endtemplate}
class MasonexCommandRunner extends CompletionCommandRunner<int> {
  /// {@macro masonex_command_runner}
  MasonexCommandRunner({
    Logger? logger,
    PubUpdater? pubUpdater,
  })  : _logger = logger ?? Logger(),
        _pubUpdater = pubUpdater ?? PubUpdater(),
        super(executableName, '🧱  masonex \u{2022} lay the foundation!') {
    argParser.addFlags();
    addCommand(AddCommand(logger: _logger));
    addCommand(CacheCommand(logger: _logger));
    addCommand(BundleCommand(logger: _logger));
    addCommand(GetCommand(logger: _logger));
    addCommand(InitCommand(logger: _logger));
    addCommand(ListCommand(logger: _logger));
    addCommand(LoginCommand(logger: _logger));
    addCommand(LogoutCommand(logger: _logger));
    addCommand(MakeCommand(logger: _logger));
    addCommand(NewCommand(logger: _logger));
    addCommand(PublishCommand(logger: _logger));
    addCommand(RemoveCommand(logger: _logger));
    addCommand(SearchCommand(logger: _logger));
    addCommand(UnbundleCommand(logger: _logger));
    addCommand(UpdateCommand(logger: _logger, pubUpdater: _pubUpdater));
    addCommand(UpgradeCommand(logger: _logger));
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
        ..info(e.usage);
      return ExitCode.usage.code;
    } on MasonexException catch (e) {
      _logger.err(e.message);
      return ExitCode.usage.code;
    } on ProcessException catch (error) {
      _logger.err(error.message);
      return ExitCode.unavailable.code;
    } catch (error) {
      _logger.err('$error');
      return ExitCode.software.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.command?.name == 'completion') {
      await super.runCommand(topLevelResults);
      return ExitCode.success.code;
    }

    int? exitCode = ExitCode.unavailable.code;
    if (topLevelResults['version'] == true) {
      _logger.info('''
masonex_cli $packageVersion • command-line interface
masonex ${masonex.packageVersion} • core templating engine''');
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }
    if (topLevelResults.command?.name != 'update') await _checkForUpdates();
    return exitCode;
  }

  Future<void> _checkForUpdates() async {
    try {
      final latestVersion = await _pubUpdater.getLatestVersion(packageName);
      final isUpToDate = packageVersion == latestVersion;
      if (!isUpToDate) {
        final changelogLink = lightCyan.wrap(
          styleUnderlined.wrap(
            link(
              uri: Uri.parse(
                'https://github.com/felangel/masonex/releases/tag/masonex_cli-v$latestVersion',
              ),
            ),
          ),
        );
        _logger
          ..info('')
          ..info(
            '''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
${lightYellow.wrap('Changelog:')} $changelogLink
Run ${cyan.wrap('masonex update')} to update''',
          );
      }
    } catch (_) {}
  }
}

extension on ArgParser {
  void addFlags() {
    addFlag(
      'version',
      negatable: false,
      help: 'Print the current version.',
    );
  }
}
