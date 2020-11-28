import 'dart:io';

import 'package:args/command_runner.dart';

import 'logger.dart';
import 'mason_cache.dart';

/// The base class for all mason executable commands.
abstract class MasonCommand extends Command<int> {
  /// [MasonCache] which contains all remote brick templates.
  MasonCache get cache => _cache ??= MasonCache();

  MasonCache _cache;

  /// [Logger] instance used to wrap stdout.
  Logger get logger => _logger ??= Logger();

  Logger _logger;

  /// Return the current working directory.
  Directory get cwd => _cwd ??= Directory.current;

  /// An override for the directory to generate into; public for testing.
  set cwd(Directory value) => _cwd = value;

  Directory _cwd;
}
