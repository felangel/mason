import 'package:io/io.dart';
import 'package:mason/mason.dart';

import '../command.dart';

/// {@template cache_command}
/// `mason cache` command includes several subcommands.
/// {@endtemplate}
class CacheCommand extends MasonCommand {
  /// {@macro cache_command}
  CacheCommand({Logger? logger}) : super(logger: logger) {
    addSubcommand(ClearCacheCommand(logger: logger));
  }

  @override
  final String description = 'Interact with mason cache';

  @override
  final String name = 'cache';
}

/// {@template cache_command}
/// `mason cache clear` command which wipes the local mason cache.
/// {@endtemplate}
class ClearCacheCommand extends MasonCommand {
  /// {@macro cache_command}
  ClearCacheCommand({Logger? logger}) : super(logger: logger) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      defaultsTo: false,
      help: 'removes all bricks from disk and clears '
          'the in-memory cache',
    );
  }

  @override
  final String description = 'Clears the mason cache';

  @override
  final String name = 'clear';

  @override
  Future<int> run() async {
    final force = results['force'] == true;
    if (force) {
      logger.warn(
        'using --force\nI sure hope you know what you are doing.',
      );
    }
    final clearDone = logger.progress('clearing cache');
    clearCache(force: force);
    clearDone();
    return ExitCode.success.code;
  }
}
