import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:path/path.dart' as p;

import 'brick_yaml.dart';
import 'logger.dart';
import 'mason_cache.dart';
import 'mason_yaml.dart';

/// The base class for all mason executable commands.
abstract class MasonCommand extends Command<int> {
  /// [MasonCache] which contains all remote brick templates.
  MasonCache get cache => _cache ??= MasonCache(entryPoint.path);

  MasonCache _cache;

  /// Gets the directory containing the nearest `mason.yaml`.
  Directory get entryPoint => _entryPoint ??= MasonYaml.findNearest(cwd).parent;

  Directory _entryPoint;

  /// Gets all [BrickYaml] contents for bricks registered in the `mason.yaml`.
  Set<BrickYaml> get bricks {
    if (_bricks != null) return _bricks;
    final bricks = <BrickYaml>{};
    for (final brick in masonYaml.bricks.values) {
      final dirPath = cache.read(brick.path ?? brick.git.url);
      if (dirPath == null) break;
      final filePath = brick.git?.url != null
          ? p.join(dirPath, brick.git.path ?? '', BrickYaml.file)
          : p.join(dirPath, BrickYaml.file);
      bricks.add(
        checkedYamlDecode(
          File(filePath).readAsStringSync(),
          (m) => BrickYaml.fromJson(m),
        ).copyWith(path: filePath),
      );
    }
    _bricks = bricks;
    return _bricks;
  }

  Set<BrickYaml> _bricks;

  /// Gets path to `mason_config.json`.
  String get masonConfigPath =>
      p.join(entryPoint.path, '.mason_tool', 'mason_config.json');

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
