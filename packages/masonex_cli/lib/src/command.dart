import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:masonex/masonex.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// {@template masonex_yaml_not_found_exception}
/// Thrown when a `masonex.yaml` cannot be found locally.
/// {@endtemplate}
class MasonexYamlNotFoundException extends MasonexException {
  /// {@macro masonex_yaml_not_found_exception}
  const MasonexYamlNotFoundException()
      : super(
          'Cannot find ${MasonexYaml.file}.\nDid you forget to run masonex init?',
        );
}

/// {@template masonex_yaml_parse_exception}
/// Thrown when a `masonex.yaml` cannot be parsed.
/// {@endtemplate}
class MasonexYamlParseException extends MasonexException {
  /// {@macro masonex_yaml_parse_exception}
  const MasonexYamlParseException(super.message);
}

/// {@template brick_yaml_parse_exception}
/// Thrown when a `brick.yaml` cannot be parsed.
/// {@endtemplate}
class BrickYamlParseException extends MasonexException {
  /// {@macro brick_yaml_parse_exception}
  const BrickYamlParseException(super.message);
}

/// {@template masonex_command}
/// The base class for all masonex executable commands.
/// {@endtemplate}
abstract class MasonexCommand extends Command<int> {
  /// {@macro masonex_command}
  MasonexCommand({Logger? logger}) : _logger = logger;

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

  /// Gets the directory containing the nearest `masonex.yaml`.
  Directory get entryPoint {
    if (_entryPoint != null) return _entryPoint!;
    final nearestMasonexYaml = MasonexYaml.findNearest(cwd);
    if (nearestMasonexYaml == null ||
        nearestMasonexYaml.parent.path == BricksJson.globalDir.path) {
      throw const MasonexYamlNotFoundException();
    }
    return _entryPoint = nearestMasonexYaml.parent;
  }

  Directory? _entryPoint;

  /// Gets all [BrickYaml] contents for bricks registered in the `masonex.yaml`.
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

  /// Gets [BrickYaml] contents for bricks registered locally in `masonex.yaml`.
  Set<BrickYaml> get localBricks {
    if (_localBricks != null) return _localBricks!;
    return _localBricks = {
      if (masonexInitialized) ..._getBricks(localBricksJson!),
    };
  }

  Set<BrickYaml>? _localBricks;

  /// Returns `true` if a `masonex.yaml` file exists locally.
  /// This excludes the global masonex configuration.
  bool get masonexInitialized {
    try {
      final _ = localMasonexYamlFile;
      return true;
    } catch (_) {}
    return false;
  }

  File _getMasonexYamlFile(String entryPointPath) {
    return File(p.join(entryPointPath, MasonexYaml.file));
  }

  File? _localMasonexYamlFile;

  /// Gets the nearest `masonex.yaml` file.
  File get localMasonexYamlFile {
    if (_localMasonexYamlFile != null) return _localMasonexYamlFile!;
    final file = File(p.join(entryPoint.path, MasonexYaml.file));
    if (!file.existsSync()) throw const MasonexYamlNotFoundException();
    return _localMasonexYamlFile = file;
  }

  File? _globalMasonexYamlFile;

  /// Gets the global `masonex.yaml` file.
  File get globalMasonexYamlFile {
    if (_globalMasonexYamlFile != null) return _globalMasonexYamlFile!;
    return _globalMasonexYamlFile = _getMasonexYamlFile(BricksJson.globalDir.path);
  }

  MasonexYaml? _globalMasonexYaml;

  /// Gets the global [MasonexYaml].
  MasonexYaml get globalMasonexYaml {
    if (_globalMasonexYaml != null) return _globalMasonexYaml!;
    return _globalMasonexYaml = _getMasonexYaml(globalMasonexYamlFile);
  }

  MasonexYaml? _masonexYaml;

  /// Gets the nearest [MasonexYaml].
  MasonexYaml get localMasonexYaml {
    if (_masonexYaml != null) return _masonexYaml!;
    return _masonexYaml = _getMasonexYaml(localMasonexYamlFile);
  }

  MasonexYaml _getMasonexYaml(File file) {
    if (!file.existsSync()) return MasonexYaml.empty;
    final masonexYamlContent = file.readAsStringSync();
    try {
      return checkedYamlDecode(
        masonexYamlContent,
        (m) => MasonexYaml.fromJson(m!),
      );
    } on ParsedYamlException catch (e) {
      throw MasonexYamlParseException(
        'Malformed ${MasonexYaml.file} at ${file.path}\n${e.message}',
      );
    }
  }

  File _getMasonexLockJsonFile(String entryPointPath) {
    return File(p.join(entryPointPath, MasonexLockJson.file));
  }

  File? _localMasonexLockJsonFile;

  /// Gets the nearest `masonex-lock.json` file.
  File get localMasonexLockJsonFile {
    if (_localMasonexLockJsonFile != null) return _localMasonexLockJsonFile!;
    return _localMasonexLockJsonFile = _getMasonexLockJsonFile(entryPoint.path)
      ..createSync(recursive: true);
  }

  File? _globalMasonexLockJsonFile;

  /// Gets the global `masonex-lock.json` file.
  File get globalMasonexLockJsonFile {
    if (_globalMasonexLockJsonFile != null) return _globalMasonexLockJsonFile!;
    return _globalMasonexLockJsonFile = _getMasonexLockJsonFile(
      BricksJson.globalDir.path,
    )..createSync(recursive: true);
  }

  MasonexLockJson? _globalMasonexLockJson;

  /// Gets the global [MasonexLockJson].
  MasonexLockJson get globalMasonexLockJson {
    if (_globalMasonexLockJson != null) return _globalMasonexLockJson!;
    return _globalMasonexLockJson = _getMasonexLockJson(globalMasonexLockJsonFile);
  }

  MasonexLockJson? _localMasonexLockJson;

  /// Gets the nearest [MasonexLockJson].
  MasonexLockJson get localMasonexLockJson {
    if (_localMasonexLockJson != null) return _localMasonexLockJson!;
    return _localMasonexLockJson = _getMasonexLockJson(localMasonexLockJsonFile);
  }

  MasonexLockJson _getMasonexLockJson(File file) {
    if (!file.existsSync()) return MasonexLockJson.empty;
    final masonexLockContent = file.readAsStringSync();
    try {
      return checkedYamlDecode(
        masonexLockContent,
        (m) => MasonexLockJson.fromJson(m!),
      );
    } catch (_) {
      return MasonexLockJson.empty;
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
