import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

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

  /// [ArgResults] used for testing purposes only.
  @visibleForTesting
  ArgResults? testArgResults;

  /// [ArgResults] for the current command.
  ArgResults get results => testArgResults ?? argResults!;

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
    return {...localBricks, ...globalBricks};
  }

  /// Gets [BrickYaml] contents for bricks registered globally.
  Set<BrickYaml> get globalBricks {
    if (_globalBricks != null) return _globalBricks!;
    return _globalBricks = _getBricks(globalBricksJson);
  }

  Set<BrickYaml>? _globalBricks;

  /// Gets [BrickYaml] contents for bricks registered locally in `mason.yaml`.
  Set<BrickYaml> get localBricks {
    if (_localBricks != null) return _localBricks!;
    return _localBricks = {
      if (masonInitialized) ..._getBricks(localBricksJson!),
    };
  }

  Set<BrickYaml>? _localBricks;

  /// Returns `true` if a `mason.yaml` file exists locally.
  /// This excludes the global mason configuration.
  bool get masonInitialized {
    try {
      final _ = localMasonYamlFile;
      return true;
    } catch (_) {}
    return false;
  }

  File _getMasonYamlFile(String entryPointPath) {
    return File(p.join(entryPointPath, MasonYaml.file));
  }

  File? _localMasonYamlFile;

  /// Gets the nearest `mason.yaml` file.
  File get localMasonYamlFile {
    if (_localMasonYamlFile != null) return _localMasonYamlFile!;
    final file = File(p.join(entryPoint.path, MasonYaml.file));
    if (!file.existsSync()) throw const MasonYamlNotFoundException();
    return _localMasonYamlFile = file;
  }

  File? _globalMasonYamlFile;

  /// Gets the global `mason.yaml` file.
  File get globalMasonYamlFile {
    if (_globalMasonYamlFile != null) return _globalMasonYamlFile!;
    return _globalMasonYamlFile = _getMasonYamlFile(BricksJson.globalDir.path);
  }

  MasonYaml? _globalMasonYaml;

  /// Gets the global [MasonYaml].
  MasonYaml get globalMasonYaml {
    if (_globalMasonYaml != null) return _globalMasonYaml!;
    return _globalMasonYaml = _getMasonYaml(globalMasonYamlFile);
  }

  MasonYaml? _masonYaml;

  /// Gets the nearest [MasonYaml].
  MasonYaml get localMasonYaml {
    if (_masonYaml != null) return _masonYaml!;
    return _masonYaml = _getMasonYaml(localMasonYamlFile);
  }

  MasonYaml _getMasonYaml(File file) {
    if (!file.existsSync()) return MasonYaml.empty;
    final masonYamlContent = file.readAsStringSync();
    try {
      return checkedYamlDecode(
        masonYamlContent,
        (m) => MasonYaml.fromJson(m!),
      );
    } on ParsedYamlException catch (e) {
      throw MasonYamlParseException(
        'Malformed ${MasonYaml.file} at ${file.path}\n${e.message}',
      );
    }
  }

  File _getMasonLockJsonFile(String entryPointPath) {
    return File(p.join(entryPointPath, MasonLockJson.file));
  }

  File? _localMasonLockJsonFile;

  /// Gets the nearest `mason-lock.json` file.
  File get localMasonLockJsonFile {
    if (_localMasonLockJsonFile != null) return _localMasonLockJsonFile!;
    return _localMasonLockJsonFile = _getMasonLockJsonFile(entryPoint.path)
      ..createSync(recursive: true);
  }

  File? _globalMasonLockJsonFile;

  /// Gets the global `mason-lock.json` file.
  File get globalMasonLockJsonFile {
    if (_globalMasonLockJsonFile != null) return _globalMasonLockJsonFile!;
    return _globalMasonLockJsonFile = _getMasonLockJsonFile(
      BricksJson.globalDir.path,
    )..createSync(recursive: true);
  }

  MasonLockJson? _globalMasonLockJson;

  /// Gets the global [MasonLockJson].
  MasonLockJson get globalMasonLockJson {
    if (_globalMasonLockJson != null) return _globalMasonLockJson!;
    return _globalMasonLockJson = _getMasonLockJson(globalMasonLockJsonFile);
  }

  MasonLockJson? _localMasonLockJson;

  /// Gets the nearest [MasonLockJson].
  MasonLockJson get localMasonLockJson {
    if (_localMasonLockJson != null) return _localMasonLockJson!;
    return _localMasonLockJson = _getMasonLockJson(localMasonLockJsonFile);
  }

  MasonLockJson _getMasonLockJson(File file) {
    if (!file.existsSync()) return MasonLockJson.empty;
    final masonLockContent = file.readAsStringSync();
    try {
      return checkedYamlDecode(
        masonLockContent,
        (m) => MasonLockJson.fromJson(m!),
      );
    } catch (_) {
      return MasonLockJson.empty;
    }
  }

  /// [Logger] instance used to wrap stdout.
  Logger get logger => _logger ??= Logger();

  Logger? _logger;

  /// Return the current working directory.
  Directory get cwd => Directory.current;

  /// Gets all [BrickYaml] instances for the provided [bricksJson].
  Set<BrickYaml> _getBricks(BricksJson bricksJson) {
    final bricks = <BrickYaml>{};
    for (final entry in bricksJson.cache.entries) {
      final dirPath = entry.value;
      final filePath = p.join(dirPath, BrickYaml.file);
      final file = File(filePath);
      if (!file.existsSync()) throw BrickNotFoundException(dirPath);
      try {
        final brickYaml = checkedYamlDecode(
          file.readAsStringSync(),
          (m) => BrickYaml.fromJson(m!),
        ).copyWith(path: filePath);
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
