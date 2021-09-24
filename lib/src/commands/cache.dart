import 'package:mason/mason.dart';

import '../bricks_json.dart';
import '../command.dart';
import '../io.dart';

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
  ClearCacheCommand({Logger? logger}) : super(logger: logger);

  @override
  final String description = 'Clears the mason cache.';

  @override
  final String name = 'clear';

  @override
  Future<int> run() async {
    final clearDone = logger.progress('clearing cache');

    localBricksJson?.clear();
    try {
      BricksJson.rootDir.deleteSync(recursive: true);
    } catch (_) {}

    clearDone();
    return ExitCode.success.code;
  }
}
