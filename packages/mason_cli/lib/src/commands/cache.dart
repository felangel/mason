import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';

/// {@template cache_command}
/// `mason cache` command includes several subcommands.
/// {@endtemplate}
class CacheCommand extends MasonCommand {
  /// {@macro cache_command}
  CacheCommand({Logger? logger}) : super(logger: logger) {
    addSubcommand(ClearCacheCommand(logger: logger));
  }

  @override
  final String description = 'Interact with mason cache.';

  @override
  final String name = 'cache';
}

/// {@template cache_command}
/// `mason cache clear` command which clears all local bricks.
/// {@endtemplate}
class ClearCacheCommand extends MasonCommand {
  /// {@macro cache_command}
  ClearCacheCommand({super.logger});

  @override
  final String description = 'Clears the mason cache.';

  @override
  final String name = 'clear';

  @override
  Future<int> run() async {
    final progress = logger.progress('Clearing cache');

    localBricksJson?.clear();
    try {
      BricksJson.rootDir.deleteSync(recursive: true);
    } catch (_) {}

    progress.complete('Cache cleared');
    return ExitCode.success.code;
  }
}
