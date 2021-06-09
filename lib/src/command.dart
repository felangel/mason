import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:path/path.dart' as p;

import 'brick_yaml.dart';
import 'bricks_json.dart';
import 'exception.dart';
import 'logger.dart';
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
  const MasonYamlNotFoundException()
      : super(
          'Cannot find ${MasonYaml.file}.\nDid you forget to run mason init?',
        );
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

  /// [BricksJson] which contains all local bricks.
  BricksJson? get localBricksJson => _localBricksJson;

  /// [BricksJson] which contains all global bricks.
  BricksJson get globalBricksJson => _globalBricksJson;

  late final BricksJson _globalBricksJson = BricksJson.global();

  late final BricksJson? _localBricksJson =
      __entryPoint != null ? BricksJson(directory: __entryPoint!) : null;

  Directory? get __entryPoint {
    try {
      return entryPoint;
    } catch (_) {}
    return null;
  }

  /// Gets the directory containing the nearest `mason.yaml`.
  Directory get entryPoint {
    if (_entryPoint != null) return _entryPoint!;
    final nearestMasonYaml = MasonYaml.findNearest(cwd);
    if (nearestMasonYaml == null ||
        nearestMasonYaml.parent.path == BricksJson.globalDir.path) {
      throw const MasonYamlNotFoundException();
    }
    return _entryPoint = nearestMasonYaml.parent;
  }

  Directory? _entryPoint;

  /// Gets all [BrickYaml] contents for bricks registered in the `mason.yaml`.
  /// Includes globally registered bricks.
  Set<BrickYaml> get bricks {
    if (_bricks != null) return _bricks!;
    return _bricks = {
      if (masonInitialized) ..._getBricks(masonYaml),
      ..._getBricks(
        _getMasonYaml(_getMasonYamlFile(BricksJson.globalDir.path)),
      ),
    };
  }

  Set<BrickYaml>? _bricks;

  /// Returns `true` if a `mason.yaml` file exists locally.
  /// This excludes the global mason configuration.
  bool get masonInitialized {
    try {
      final _ = masonYamlFile;
      return true;
    } catch (_) {}
    return false;
  }

  /// Gets the nearest `mason.yaml` file.
  File get masonYamlFile {
    if (_masonYamlFile != null) return _masonYamlFile!;
    final file = File(p.join(entryPoint.path, MasonYaml.file));
    if (!file.existsSync()) throw const MasonYamlNotFoundException();
    return _masonYamlFile = file;
  }

  File? _masonYamlFile;

  /// Gets the global `mason.yaml` file.
  File get globalMasonYamlFile {
    if (_globalMasonYamlFile != null) return _globalMasonYamlFile!;
    return _globalMasonYamlFile = _getMasonYamlFile(BricksJson.globalDir.path);
  }

  File? _globalMasonYamlFile;

  File _getMasonYamlFile(String entryPointPath) {
    return File(p.join(entryPointPath, MasonYaml.file));
  }

  /// Gets the global [MasonYaml].
  MasonYaml get globalMasonYaml {
    if (_globalMasonYaml != null) return _globalMasonYaml!;
    return _globalMasonYaml = _getMasonYaml(globalMasonYamlFile);
  }

  MasonYaml? _globalMasonYaml;

  /// Gets the nearest [MasonYaml].
  MasonYaml get masonYaml {
    if (_masonYaml != null) return _masonYaml!;
    return _masonYaml = _getMasonYaml(masonYamlFile);
  }

  MasonYaml? _masonYaml;

  MasonYaml _getMasonYaml(File file) {
    if (!file.existsSync()) return MasonYaml.empty;
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

  /// The path to the cached brick directory if it exists.
  /// Returns `null` if the brick is not cached.
  String? _cacheDirectory(Brick brick) {
    if (localBricksJson != null) {
      final path = localBricksJson!.getPath(brick);
      if (path != null) return path;
    }
    return globalBricksJson.getPath(brick);
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
