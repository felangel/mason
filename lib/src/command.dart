import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:path/path.dart' as p;

import 'logger.dart';
import 'mason_cache.dart';
import 'mason_yaml.dart';

/// The base class for all mason executable commands.
abstract class MasonCommand extends Command<int> {
  /// [MasonCache] which contains all remote brick templates.
  MasonCache get cache => _cache ??= MasonCache();

  MasonCache _cache;

  /// Gets the directory containing the nearest `mason.yaml`.
  Directory get entryPoint => _entryPoint ??= MasonYaml.findNearest(cwd).parent;

  Directory _entryPoint;

  /// Gets the nearest `mason.yaml` file.
  File get masonYamlFile => File(p.join(entryPoint.path, MasonYaml.file));

  /// Gets the nearest [MasonYaml].
  MasonYaml get masonYaml {
    if (_masonYaml != null) return _masonYaml;
    final masonYamlContent = File(
      p.join(entryPoint.path, MasonYaml.file),
    ).readAsStringSync();
    _masonYaml = checkedYamlDecode(
      masonYamlContent,
      (m) => MasonYaml.fromJson(m),
    );
    return _masonYaml;
  }

  MasonYaml _masonYaml;

  /// [Logger] instance used to wrap stdout.
  Logger get logger => _logger ??= Logger();

  Logger _logger;

  /// Return the current working directory.
  Directory get cwd => _cwd ??= Directory.current;

  /// An override for the directory to generate into; public for testing.
  set cwd(Directory value) => _cwd = value;

  Directory _cwd;
}
