import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
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

/// {@template mason_command}
/// The base class for all mason executable commands.
/// {@endtemplate}
abstract class MasonCommand extends Command<int> {
  /// {@macro mason_command}
  MasonCommand({Logger? logger}) : _logger = logger;

  /// [ArgResults] for the current command.
  ArgResults get results => argResults!;

  /// [MasonCache] which contains all local brick templates.
  late final _cache = MasonCache(directory: _entryPoint);

  /// [MasonCache] which contains all global brick templates.
  late final _globalCache = MasonCache.global();

  /// Gets the directory containing the nearest `mason.yaml`.
  Directory get entryPoint {
    if (_entryPoint != null) return _entryPoint!;
    final nearestMasonYaml = MasonYaml.findNearest(cwd);
    if (nearestMasonYaml == null) {
      return _entryPoint = MasonCache.globalDir..createSync(recursive: true);
    }
    return _entryPoint = nearestMasonYaml.parent;
  }

  Directory? _entryPoint;

  /// Writes [brick] to cache.
  Future<String> writeBrick(Brick brick) => _cache.writeBrick(brick);

  /// Clear all cached bricks.
  void clearCache({bool force = false}) {
    _cache.clear(force: force);
    if (isLocalConfiguration) _globalCache.clear(force: force);
  }

  /// Writes current cache to `brick.json`.
  Future<void> flushCache() async {
    final bricksJson = _bricksJson();
    await bricksJson.create(recursive: true);
    await bricksJson.writeAsString(_cache.encode);
    if (isLocalConfiguration) {
      final globalBricks = _bricksJson(MasonCache.globalDir.path);
      await globalBricks.create(recursive: true);
      await globalBricks.writeAsString(_cache.encode);
    }
  }

  /// Gets all [BrickYaml] contents for bricks registered in the `mason.yaml`.
  /// Includes globally registered bricks.
  Set<BrickYaml> get bricks {
    if (_bricks != null) return _bricks!;
    final bricks = _getBricks(masonYaml);
    if (isLocalConfiguration) {
      bricks.addAll(
        _getBricks(_getMasonYaml(_getMasonYamlFile(MasonCache.globalDir.path))),
      );
    }
    return _bricks = bricks;
  }

  Set<BrickYaml>? _bricks;

  /// Returns `true` if a `mason.yaml` file exists locally.
  /// This excludes the global mason configuration.
  bool get isLocalConfiguration {
    try {
      return entryPoint.path != MasonCache.globalDir.path;
    } catch (_) {
      return false;
    }
  }

  /// Gets the nearest `mason.yaml` file.
  File get masonYamlFile {
    if (_masonYamlFile != null) return _masonYamlFile!;
    return _masonYamlFile = _getMasonYamlFile(entryPoint.path);
  }

  File? _masonYamlFile;

  File _getMasonYamlFile(String entryPointPath) {
    final file = File(p.join(entryPointPath, MasonYaml.file));
    if (!file.existsSync()) {
      file
        ..createSync(recursive: true)
        ..writeAsStringSync(json.encode(MasonYaml.empty.toJson()));
    }
    return file;
  }

  /// Gets the nearest [MasonYaml].
  MasonYaml get masonYaml {
    if (_masonYaml != null) return _masonYaml!;
    return _masonYaml = _getMasonYaml(masonYamlFile);
  }

  MasonYaml? _masonYaml;

  MasonYaml _getMasonYaml(File file) {
    final masonYamlContent = file.readAsStringSync();
    try {
      return _masonYaml = checkedYamlDecode(
        masonYamlContent,
        (m) => MasonYaml.fromJson(m!),
      )!;
    } on ParsedYamlException catch (e) {
      throw MasonYamlParseException(
        'Malformed ${MasonYaml.file} at ${file.path}\n${e.message}',
      );
    }
  }

  /// [Logger] instance used to wrap stdout.
  Logger get logger => _logger ??= Logger();

  Logger? _logger;

  /// Return the current working directory.
  Directory get cwd => _cwd ??= Directory.current;

  /// An override for the directory to generate into; public for testing.
  set cwd(Directory value) => _cwd = value;

  Directory? _cwd;

  /// Gets the `bricks.json` file for the current [path].
  /// Default to the [entryPoint] if no path is provided.
  File _bricksJson([String? path]) {
    final entryPointPath = path ?? entryPoint.path;
    return File(p.join(entryPointPath, '.mason', 'bricks.json'));
  }

  /// The path to the cached brick directory if it exists.
  /// Returns `null` if the brick is not cached.
  String? _cacheDirectory(Brick brick) {
    final key = _cache.getKey(brick) ?? _globalCache.getKey(brick);
    if (key == null) return null;
    return _cache.read(key) ?? _globalCache.read(key);
  }

  /// Gets all [BrickYaml] instances for the provided [masonYaml].
  Set<BrickYaml> _getBricks(MasonYaml masonYaml) {
    final bricks = <BrickYaml>{};
    for (final entry in masonYaml.bricks.entries) {
      final brick = entry.value;
      final dirPath = _cacheDirectory(brick);
      if (dirPath == null) break;
      final filePath = brick.path != null
          ? p.join(dirPath, BrickYaml.file)
          : p.join(dirPath, brick.git?.path ?? '', BrickYaml.file);
      final file = File(filePath);
      if (!file.existsSync()) throw BrickNotFoundException(filePath);
      try {
        final brickYaml = checkedYamlDecode(
          file.readAsStringSync(),
          (m) => BrickYaml.fromJson(m!),
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
    return bricks;
  }
}
