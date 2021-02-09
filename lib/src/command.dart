import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:path/path.dart' as p;

import 'brick_yaml.dart';
import 'exception.dart';
import 'logger.dart';
import 'mason_cache.dart';
import 'mason_yaml.dart';

/// {@template brick_not_found_exception}
/// Thrown when a brick registered in the `mason.yaml` cannot be found locally.
/// {@endtemplate}
class BrickNotFoundException extends MasonException {
  /// {@macro brick_not_found_exception}
  const BrickNotFoundException(String path)
      : super('Could not find brick at $path');
}

/// {@template mason_yaml_name_mismatch}
/// Thrown when a brick's name in `mason.yaml` does not match
/// the name in `brick.yaml`.
/// {@endtemplate}
class MasonYamlNameMismatch extends MasonException {
  /// {@macro mason_yaml_name_mismatch}
  MasonYamlNameMismatch(String message) : super(message);
}

/// {@template mason_yaml_not_found_exception}
/// Thrown when a `mason.yaml` cannot be found locally.
/// {@endtemplate}
class MasonYamlNotFoundException extends MasonException {
  /// {@macro mason_yaml_not_found_exception}
  const MasonYamlNotFoundException(String message) : super(message);
}

/// {@template mason_yaml_parse_exception}
/// Thrown when a `mason.yaml` cannot be parsed.
/// {@endtemplate}
class MasonYamlParseException extends MasonException {
  /// {@macro mason_yaml_parse_exception}
  const MasonYamlParseException(String message) : super(message);
}

/// {@template brick_yaml_parse_exception}
/// Thrown when a `brick.yaml` cannot be parsed.
/// {@endtemplate}
class BrickYamlParseException extends MasonException {
  /// {@macro brick_yaml_parse_exception}
  const BrickYamlParseException(String message) : super(message);
}

/// The base class for all mason executable commands.
abstract class MasonCommand extends Command<int> {
  /// [MasonCache] which contains all remote brick templates.
  MasonCache get cache => _cache ??= MasonCache(bricksJson);

  MasonCache _cache;

  /// Gets the directory containing the nearest `mason.yaml`.
  Directory get entryPoint {
    if (_entryPoint != null) return _entryPoint;
    final nearestMasonYaml = MasonYaml.findNearest(cwd);
    if (nearestMasonYaml == null) {
      throw const MasonYamlNotFoundException(
        'Could not find ${MasonYaml.file}.\nDid you forget to run mason init?',
      );
    }
    return nearestMasonYaml.parent;
  }

  Directory _entryPoint;

  /// Gets the `bricks.json` file for the current [entryPoint].
  File get bricksJson => File(p.join(entryPoint.path, '.mason', 'bricks.json'));

  /// Gets all [BrickYaml] contents for bricks registered in the `mason.yaml`.
  Set<BrickYaml> get bricks {
    if (_bricks != null) return _bricks;
    final bricks = <BrickYaml>{};
    for (final entry in masonYaml.bricks.entries) {
      final brick = entry.value;
      final dirPath = cache.read(brick.path ?? brick.git.url);
      if (dirPath == null) break;
      final filePath = brick.path != null
          ? p.join(dirPath, BrickYaml.file)
          : p.join(dirPath, brick.git.path ?? '', BrickYaml.file);
      final file = File(filePath);
      if (!file.existsSync()) {
        throw BrickNotFoundException(filePath);
      }
      try {
        final brickYaml = checkedYamlDecode(
          file.readAsStringSync(),
          (m) => BrickYaml.fromJson(m),
        ).copyWith(path: filePath);
        if (brickYaml.name != entry.key) {
          throw MasonYamlNameMismatch(
            'brick name "${brickYaml.name}": '
            'doesn\'t match provided name "${entry.key}" in ${MasonYaml.file}.',
          );
        }
        bricks.add(brickYaml);
      } on ParsedYamlException catch (e) {
        throw BrickYamlParseException(
          'Malformed ${BrickYaml.file} at ${file.path}\n${e.message}',
        );
      }
    }
    _bricks = bricks;
    return _bricks;
  }

  Set<BrickYaml> _bricks;

  /// Returns `true` if a `mason.yaml` file exists.
  bool get masonInitialized {
    try {
      final _ = masonYamlFile;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Gets the nearest `mason.yaml` file.
  File get masonYamlFile {
    final file = File(p.join(entryPoint.path, MasonYaml.file));
    if (!file.existsSync()) {
      throw const MasonYamlNotFoundException(
        'Cannot find ${MasonYaml.file}.\nDid you forget to run mason init?',
      );
    }
    return file;
  }

  /// Gets the nearest [MasonYaml].
  MasonYaml get masonYaml {
    if (_masonYaml != null) return _masonYaml;
    final masonYamlContent = masonYamlFile.readAsStringSync();
    try {
      _masonYaml = checkedYamlDecode(
        masonYamlContent,
        (m) => MasonYaml.fromJson(m),
      );
      return _masonYaml;
    } on ParsedYamlException catch (e) {
      throw MasonYamlParseException(
        'Malformed ${MasonYaml.file} at ${masonYamlFile.path}\n${e.message}',
      );
    }
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
